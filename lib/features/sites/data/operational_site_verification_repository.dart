import 'dart:convert';

import 'package:flutter/services.dart';

import '../../knowledge/domain/knowledge.dart';
import '../domain/site.dart';
import '../domain/site_verification.dart';
import 'site_discovery_repository.dart';

class AssetOperationalSiteVerificationRepository {
  const AssetOperationalSiteVerificationRepository({
    this.overlayAssetPath = 'assets/data/sites.verified.overlay.json',
    this.siteDiscoveryRepository = const AssetSiteDiscoveryRepository(),
  });

  final String overlayAssetPath;
  final AssetSiteDiscoveryRepository siteDiscoveryRepository;

  Future<SiteVerificationResult> loadSnapshot() async {
    final discovery = await siteDiscoveryRepository.loadSnapshot();
    final baseline = discovery.snapshot;
    final raw = await rootBundle.loadString(overlayAssetPath);
    final document = Map<String, dynamic>.from(jsonDecode(raw) as Map);

    if (document['format'] != 'nexo-industrial-site-verifications') {
      throw const FormatException('Invalid site verification overlay format.');
    }
    if (document['version'] != 1) {
      throw const FormatException('Unsupported site verification overlay version.');
    }

    final records = (document['records'] as List<dynamic>? ?? const [])
        .map(
          (row) => parseOperationalSiteVerification(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);

    return const SiteVerificationEngine().apply(baseline, records);
  }
}

class SiteVerificationEngine {
  const SiteVerificationEngine();

  SiteVerificationResult apply(
    SiteSnapshot baseline,
    List<OperationalSiteVerification> verifications,
  ) {
    final sitesById = <String, Site>{
      for (final site in baseline.sites) site.id: site,
    };
    final verificationIds = <String>{};
    final verifiedSiteIds = <String>{};
    final evidenceById = <String, EvidenceRef>{};
    final claims = <KnowledgeClaim>[];
    final operationalOrganizations = <String>{};

    for (final verification in verifications) {
      if (!verificationIds.add(verification.id)) {
        throw FormatException(
          'Duplicate site verification id: ${verification.id}',
        );
      }
      if (!verifiedSiteIds.add(verification.siteId)) {
        throw FormatException(
          'Only one current verification per site is allowed in CONTRACT 021: '
          '${verification.siteId}',
        );
      }

      final site = sitesById[verification.siteId];
      if (site == null) {
        throw FormatException(
          'Verification references unknown site: ${verification.siteId}',
        );
      }
      if (site.organizationRuc != verification.organizationRuc) {
        throw FormatException(
          'Verification organization/site mismatch: ${verification.id}',
        );
      }
      if (verification.evidence.isEmpty) {
        throw FormatException(
          'Site verification requires evidence: ${verification.id}',
        );
      }
      if (verification.decision == OperationalSiteDecision.operational &&
          verification.function == SiteFunction.unknown) {
        throw FormatException(
          'Operational site verification requires a concrete function: '
          '${verification.id}',
        );
      }

      final validFrom = verification.validFrom ?? verification.verifiedAt;
      final validUntil = verification.validUntil;
      if (validUntil != null && validUntil.isBefore(validFrom)) {
        throw FormatException(
          'Site verification validity ends before it starts: '
          '${verification.id}',
        );
      }

      for (final evidence in verification.evidence) {
        _validateEvidence(evidence, verification.id);
        final existing = evidenceById[evidence.id];
        if (existing != null &&
            (existing.locator != evidence.locator ||
                existing.sourceType != evidence.sourceType)) {
          throw FormatException(
            'Conflicting site verification evidence id: ${evidence.id}',
          );
        }
        evidenceById[evidence.id] = existing ?? evidence;
      }

      final resolvedFunction = verification.function == SiteFunction.unknown
          ? site.function
          : verification.function;

      sitesById[site.id] = Site(
        id: site.id,
        organizationRuc: site.organizationRuc,
        displayLabel: site.displayLabel,
        function: resolvedFunction,
        identityBasis: site.identityBasis,
        operationalStatus: verification.operationalStatus,
        sourceClaimId: site.sourceClaimId,
      );

      if (verification.decision == OperationalSiteDecision.operational) {
        operationalOrganizations.add(site.organizationRuc);
      }

      claims.add(
        KnowledgeClaim(
          id: 'claim:site:${site.id}:operational-status:${verification.id}',
          subject: KnowledgeSubjectRef(
            type: KnowledgeSubjectType.site,
            id: site.id,
          ),
          predicate: 'site.operational_status',
          value: Map<String, Object?>.unmodifiable({
            'decision': _decisionName(verification.decision),
            'function': _siteFunctionName(resolvedFunction),
            'organization_ruc': site.organizationRuc,
            'verification_id': verification.id,
          }),
          origin: verification.claimOrigin,
          temporalMode: KnowledgeTemporalMode.current,
          confidence: _verificationConfidence(verification.method),
          asOf: verification.verifiedAt,
          validFrom: validFrom,
          validUntil: validUntil,
          evidenceIds: verification.evidence
              .map((item) => item.id)
              .toList(growable: false),
          metadata: {
            'verification_method': _methodName(verification.method),
            ..._optionalMetadata('reviewer', verification.reviewer),
            ..._optionalMetadata('notes', verification.notes),
          },
        ),
      );
    }

    final remainingGaps = baseline.gaps
        .where(
          (gap) =>
              gap.predicate != 'organization.operational_site' ||
              !operationalOrganizations.contains(gap.subject.id),
        )
        .toList(growable: false);

    return SiteVerificationResult(
      snapshot: SiteSnapshot(
        sites: baseline.sites
            .map((site) => sitesById[site.id]!)
            .toList(growable: false),
        placements: baseline.placements,
        gaps: remainingGaps,
      ),
      verifications: verifications,
      claims: claims,
      evidence: evidenceById.values.toList(growable: false),
    );
  }
}

OperationalSiteVerification parseOperationalSiteVerification(
  Map<String, dynamic> row,
) {
  final id = _requiredText(row, 'id');
  final siteId = _requiredText(row, 'site_id');
  final organizationRuc = _requiredText(row, 'organization_ruc');
  final verifiedAt = DateTime.tryParse(_requiredText(row, 'verified_at'));
  if (verifiedAt == null) {
    throw FormatException('Invalid verified_at for site verification: $id');
  }

  final evidenceRows = row['evidence'] as List<dynamic>? ?? const [];
  final evidence = evidenceRows
      .map(
        (item) => _parseEvidence(
          Map<String, dynamic>.from(item as Map),
          verificationId: id,
        ),
      )
      .toList(growable: false);

  return OperationalSiteVerification(
    id: id,
    siteId: siteId,
    organizationRuc: organizationRuc,
    decision: _parseDecision(_requiredText(row, 'decision')),
    function: _parseSiteFunction(_requiredText(row, 'site_function')),
    method: _parseMethod(_requiredText(row, 'method')),
    verifiedAt: verifiedAt,
    validFrom: _optionalDate(row['valid_from'], field: 'valid_from', id: id),
    validUntil: _optionalDate(row['valid_until'], field: 'valid_until', id: id),
    reviewer: _optionalText(row['reviewer']),
    notes: _optionalText(row['notes']),
    evidence: evidence,
  );
}

EvidenceRef _parseEvidence(
  Map<String, dynamic> row, {
  required String verificationId,
}) {
  final id = _requiredText(row, 'id');
  final sourceType = switch (_requiredText(row, 'source_type')) {
    'url' => EvidenceSourceType.url,
    'dataset' => EvidenceSourceType.dataset,
    'user_activity' => EvidenceSourceType.userActivity,
    _ => throw FormatException(
        'Unsupported evidence source_type in $verificationId: '
        '${row['source_type']}',
      ),
  };

  return EvidenceRef(
    id: id,
    sourceType: sourceType,
    locator: _requiredText(row, 'locator'),
    reviewedAt: _optionalDate(
      row['reviewed_at'],
      field: 'reviewed_at',
      id: verificationId,
    ),
    observedAt: _optionalDate(
      row['observed_at'],
      field: 'observed_at',
      id: verificationId,
    ),
    summary: _optionalText(row['summary']),
    metadata: const {
      'knowledge_family': 'site_verification',
    },
  );
}

void _validateEvidence(EvidenceRef evidence, String verificationId) {
  if (evidence.id.trim().isEmpty || evidence.locator.trim().isEmpty) {
    throw FormatException(
      'Incomplete evidence in site verification: $verificationId',
    );
  }
  if (evidence.sourceType == EvidenceSourceType.url) {
    final uri = Uri.tryParse(evidence.locator);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw FormatException(
        'Public site verification evidence must use HTTPS: $verificationId',
      );
    }
  }
}

OperationalSiteDecision _parseDecision(String value) {
  return switch (value) {
    'operational' => OperationalSiteDecision.operational,
    'not_operational' => OperationalSiteDecision.notOperational,
    _ => throw FormatException('Unsupported site verification decision: $value'),
  };
}

OperationalSiteVerificationMethod _parseMethod(String value) {
  return switch (value) {
    'public_source' => OperationalSiteVerificationMethod.publicSource,
    'official_source' => OperationalSiteVerificationMethod.officialSource,
    'field_observation' => OperationalSiteVerificationMethod.fieldObservation,
    'manual_review' => OperationalSiteVerificationMethod.manualReview,
    _ => throw FormatException('Unsupported site verification method: $value'),
  };
}

SiteFunction _parseSiteFunction(String value) {
  return switch (value) {
    'unknown' => SiteFunction.unknown,
    'headquarters' => SiteFunction.headquarters,
    'office' => SiteFunction.office,
    'plant' => SiteFunction.plant,
    'mine' => SiteFunction.mine,
    'warehouse' => SiteFunction.warehouse,
    'workshop' => SiteFunction.workshop,
    'shipyard' => SiteFunction.shipyard,
    'terminal' => SiteFunction.terminal,
    'project_site' => SiteFunction.projectSite,
    _ => throw FormatException('Unsupported site function: $value'),
  };
}

String _decisionName(OperationalSiteDecision value) {
  return switch (value) {
    OperationalSiteDecision.operational => 'operational',
    OperationalSiteDecision.notOperational => 'not_operational',
  };
}

String _methodName(OperationalSiteVerificationMethod value) {
  return switch (value) {
    OperationalSiteVerificationMethod.publicSource => 'public_source',
    OperationalSiteVerificationMethod.officialSource => 'official_source',
    OperationalSiteVerificationMethod.fieldObservation => 'field_observation',
    OperationalSiteVerificationMethod.manualReview => 'manual_review',
  };
}

String _siteFunctionName(SiteFunction value) {
  return switch (value) {
    SiteFunction.unknown => 'unknown',
    SiteFunction.headquarters => 'headquarters',
    SiteFunction.office => 'office',
    SiteFunction.plant => 'plant',
    SiteFunction.mine => 'mine',
    SiteFunction.warehouse => 'warehouse',
    SiteFunction.workshop => 'workshop',
    SiteFunction.shipyard => 'shipyard',
    SiteFunction.terminal => 'terminal',
    SiteFunction.projectSite => 'project_site',
  };
}

KnowledgeConfidence _verificationConfidence(
  OperationalSiteVerificationMethod method,
) {
  return switch (method) {
    OperationalSiteVerificationMethod.officialSource ||
    OperationalSiteVerificationMethod.fieldObservation =>
      KnowledgeConfidence.high,
    OperationalSiteVerificationMethod.publicSource ||
    OperationalSiteVerificationMethod.manualReview =>
      KnowledgeConfidence.medium,
  };
}

String _requiredText(Map<String, dynamic> row, String field) {
  final value = _optionalText(row[field]);
  if (value == null) {
    throw FormatException('Missing required field $field.');
  }
  return value;
}

String? _optionalText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

DateTime? _optionalDate(
  Object? value, {
  required String field,
  required String id,
}) {
  final text = _optionalText(value);
  if (text == null) return null;
  final parsed = DateTime.tryParse(text);
  if (parsed == null) {
    throw FormatException('Invalid $field in site verification: $id');
  }
  return parsed;
}


Map<String, String> _optionalMetadata(String key, Object? value) {
  final text = _optionalText(value);
  return text == null ? const {} : {key: text};
}
