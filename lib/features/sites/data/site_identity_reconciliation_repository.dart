import 'dart:convert';

import 'package:flutter/services.dart';

import '../../knowledge/domain/knowledge.dart';
import '../domain/site.dart';
import '../domain/site_identity_reconciliation.dart';
import 'site_discovery_repository.dart';

class AssetSiteIdentityReconciliationRepository {
  const AssetSiteIdentityReconciliationRepository({
    this.overlayAssetPath =
        'assets/data/site.identity.reconciliation.overlay.json',
    this.siteDiscoveryRepository = const AssetSiteDiscoveryRepository(),
  });

  final String overlayAssetPath;
  final AssetSiteDiscoveryRepository siteDiscoveryRepository;

  Future<SiteIdentityReconciliationResult> loadSnapshot() async {
    final discovery = await siteDiscoveryRepository.loadSnapshot();
    final raw = await rootBundle.loadString(overlayAssetPath);
    final document = Map<String, dynamic>.from(jsonDecode(raw) as Map);

    if (document['format'] != 'nexo-industrial-site-identity-reconciliations') {
      throw const FormatException(
        'Invalid site identity reconciliation overlay format.',
      );
    }
    if (document['version'] != 1) {
      throw const FormatException(
        'Unsupported site identity reconciliation overlay version.',
      );
    }

    final records = (document['records'] as List<dynamic>? ?? const [])
        .map(
          (row) => parseSiteIdentityReconciliationRecord(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);

    return const SiteIdentityReconciliationEngine().apply(
      discovery.snapshot,
      records,
    );
  }
}

class SiteIdentityReconciliationEngine {
  const SiteIdentityReconciliationEngine();

  SiteIdentityReconciliationResult apply(
    SiteSnapshot baseline,
    List<SiteIdentityReconciliationRecord> reconciliations,
  ) {
    final sitesById = <String, Site>{
      for (final site in baseline.sites) site.id: site,
    };
    final placements = [...baseline.placements];
    final gaps = [...baseline.gaps];
    final ids = <String>{};
    final touchedPairs = <String>{};
    final aliases = <SiteAlias>[];
    final claims = <KnowledgeClaim>[];
    final evidenceById = <String, EvidenceRef>{};

    for (final reconciliation in reconciliations) {
      if (!ids.add(reconciliation.id)) {
        throw FormatException(
          'Duplicate site reconciliation id: ${reconciliation.id}',
        );
      }
      if (reconciliation.leftSiteId == reconciliation.rightSiteId) {
        throw FormatException(
          'Site reconciliation requires two distinct Site IDs: '
          '${reconciliation.id}',
        );
      }

      final left = sitesById[reconciliation.leftSiteId];
      final right = sitesById[reconciliation.rightSiteId];
      if (left == null || right == null) {
        throw FormatException(
          'Site reconciliation references unknown Site: '
          '${reconciliation.id}',
        );
      }
      if (left.organizationRuc != reconciliation.organizationRuc ||
          right.organizationRuc != reconciliation.organizationRuc) {
        throw FormatException(
          'Site reconciliation organization mismatch: '
          '${reconciliation.id}',
        );
      }

      final pair = [
        reconciliation.leftSiteId,
        reconciliation.rightSiteId,
      ]..sort();
      if (!touchedPairs.add(pair.join('|'))) {
        throw FormatException(
          'Duplicate Site pair reconciliation: ${reconciliation.id}',
        );
      }
      if (reconciliation.evidence.isEmpty) {
        throw FormatException(
          'Site reconciliation requires evidence: ${reconciliation.id}',
        );
      }

      for (final evidence in reconciliation.evidence) {
        _validateEvidence(evidence, reconciliation.id);
        final existing = evidenceById[evidence.id];
        if (existing != null &&
            (existing.locator != evidence.locator ||
                existing.sourceType != evidence.sourceType)) {
          throw FormatException(
            'Conflicting reconciliation evidence id: ${evidence.id}',
          );
        }
        evidenceById[evidence.id] = existing ?? evidence;
      }

      String? canonicalSiteId = reconciliation.canonicalSiteId;
      if (reconciliation.relation == SiteIdentityRelation.sameSite) {
        if (canonicalSiteId == null ||
            (canonicalSiteId != left.id && canonicalSiteId != right.id)) {
          throw FormatException(
            'SAME_SITE requires canonical Site from reconciled pair: '
            '${reconciliation.id}',
          );
        }

        final alias = canonicalSiteId == left.id ? right : left;
        final canonical = canonicalSiteId == left.id ? left : right;

        final aliasPlacements = placements
            .where((placement) => placement.siteId == alias.id)
            .toList(growable: false);
        if (aliasPlacements.isNotEmpty) {
          throw FormatException(
            'Cannot merge alias Site that already owns Placement: '
            '${reconciliation.id}',
          );
        }

        final unsupportedAliasGaps = gaps.where(
          (gap) =>
              gap.subject.type == KnowledgeSubjectType.site &&
              gap.subject.id == alias.id &&
              gap.predicate != 'site.placement',
        );
        if (unsupportedAliasGaps.isNotEmpty) {
          throw FormatException(
            'Cannot merge alias Site with unresolved non-placement gaps: '
            '${reconciliation.id}',
          );
        }

        final resolvedFunction = canonical.function == SiteFunction.unknown
            ? alias.function
            : canonical.function;

        sitesById[canonical.id] = Site(
          id: canonical.id,
          organizationRuc: canonical.organizationRuc,
          displayLabel: canonical.displayLabel,
          function: resolvedFunction,
          identityBasis: canonical.identityBasis,
          operationalStatus: canonical.operationalStatus,
          sourceClaimId: canonical.sourceClaimId,
        );
        sitesById.remove(alias.id);

        gaps.removeWhere(
          (gap) =>
              gap.subject.type == KnowledgeSubjectType.site &&
              gap.subject.id == alias.id,
        );

        aliases.add(
          SiteAlias(
            aliasSiteId: alias.id,
            canonicalSiteId: canonical.id,
            aliasLabel: alias.displayLabel,
            reconciliationId: reconciliation.id,
          ),
        );
      } else if (canonicalSiteId != null) {
        throw FormatException(
          'Only SAME_SITE may declare canonical Site: '
          '${reconciliation.id}',
        );
      }

      claims.add(
        KnowledgeClaim(
          id: 'claim:site-reconciliation:${reconciliation.id}',
          subject: KnowledgeSubjectRef(
            type: KnowledgeSubjectType.site,
            id: canonicalSiteId ?? reconciliation.leftSiteId,
          ),
          predicate: 'site.identity_relation',
          value: Map<String, Object?>.unmodifiable({
            'left_site_id': reconciliation.leftSiteId,
            'right_site_id': reconciliation.rightSiteId,
            'relation': _relationName(reconciliation.relation),
            if (canonicalSiteId != null) 'canonical_site_id': canonicalSiteId,
          }),
          origin: KnowledgeOrigin.derived,
          temporalMode: KnowledgeTemporalMode.current,
          confidence: reconciliation.confidence,
          asOf: reconciliation.reviewedAt,
          evidenceIds: reconciliation.evidence
              .map((item) => item.id)
              .toList(growable: false),
          metadata: {
            'reconciliation_method': _methodName(reconciliation.method),
            ..._optionalMetadata('rationale', reconciliation.rationale),
          },
        ),
      );
    }

    return SiteIdentityReconciliationResult(
      snapshot: SiteSnapshot(
        sites: sitesById.values.toList(growable: false),
        placements: placements,
        gaps: gaps,
      ),
      reconciliations: reconciliations,
      aliases: aliases,
      claims: claims,
      evidence: evidenceById.values.toList(growable: false),
    );
  }
}

SiteIdentityReconciliationRecord parseSiteIdentityReconciliationRecord(
  Map<String, dynamic> row,
) {
  final id = _requiredText(row, 'id');
  final reviewedAt = DateTime.tryParse(_requiredText(row, 'reviewed_at'));
  if (reviewedAt == null) {
    throw FormatException('Invalid reviewed_at: $id');
  }

  final evidence = (row['evidence'] as List<dynamic>? ?? const [])
      .map(
        (item) => _parseEvidence(
          Map<String, dynamic>.from(item as Map),
          reconciliationId: id,
        ),
      )
      .toList(growable: false);

  return SiteIdentityReconciliationRecord(
    id: id,
    organizationRuc: _requiredText(row, 'organization_ruc'),
    leftSiteId: _requiredText(row, 'left_site_id'),
    rightSiteId: _requiredText(row, 'right_site_id'),
    relation: _parseRelation(_requiredText(row, 'relation')),
    method: _parseMethod(_requiredText(row, 'method')),
    confidence: _parseConfidence(_requiredText(row, 'confidence')),
    reviewedAt: reviewedAt,
    evidence: evidence,
    canonicalSiteId: _optionalText(row['canonical_site_id']),
    rationale: _optionalText(row['rationale']),
  );
}

EvidenceRef _parseEvidence(
  Map<String, dynamic> row, {
  required String reconciliationId,
}) {
  final sourceType = switch (_requiredText(row, 'source_type')) {
    'url' => EvidenceSourceType.url,
    'dataset' => EvidenceSourceType.dataset,
    'user_activity' => EvidenceSourceType.userActivity,
    _ => throw FormatException(
        'Unsupported reconciliation evidence type: $reconciliationId',
      ),
  };

  return EvidenceRef(
    id: _requiredText(row, 'id'),
    sourceType: sourceType,
    locator: _requiredText(row, 'locator'),
    reviewedAt: _optionalDate(row['reviewed_at']),
    summary: _optionalText(row['summary']),
    metadata: const {'knowledge_family': 'site_identity_reconciliation'},
  );
}

void _validateEvidence(EvidenceRef evidence, String reconciliationId) {
  if (evidence.sourceType == EvidenceSourceType.url) {
    final uri = Uri.tryParse(evidence.locator);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw FormatException(
        'Public reconciliation evidence must use HTTPS: $reconciliationId',
      );
    }
  }
}

SiteIdentityRelation _parseRelation(String value) => switch (value) {
      'same_site' => SiteIdentityRelation.sameSite,
      'adjacent_site' => SiteIdentityRelation.adjacentSite,
      'distinct_site' => SiteIdentityRelation.distinctSite,
      'unknown' => SiteIdentityRelation.unknown,
      _ => throw FormatException('Unsupported Site identity relation: $value'),
    };

SiteIdentityReconciliationMethod _parseMethod(String value) => switch (value) {
      'official_cross_reference' =>
        SiteIdentityReconciliationMethod.officialCrossReference,
      'official_source' => SiteIdentityReconciliationMethod.officialSource,
      'field_observation' => SiteIdentityReconciliationMethod.fieldObservation,
      'manual_review' => SiteIdentityReconciliationMethod.manualReview,
      _ => throw FormatException('Unsupported reconciliation method: $value'),
    };

KnowledgeConfidence _parseConfidence(String value) => switch (value) {
      'high' => KnowledgeConfidence.high,
      'medium' => KnowledgeConfidence.medium,
      'low' => KnowledgeConfidence.low,
      'very_low' => KnowledgeConfidence.veryLow,
      'unknown' => KnowledgeConfidence.unknown,
      _ => throw FormatException('Unsupported reconciliation confidence: $value'),
    };

String _relationName(SiteIdentityRelation relation) => switch (relation) {
      SiteIdentityRelation.sameSite => 'same_site',
      SiteIdentityRelation.adjacentSite => 'adjacent_site',
      SiteIdentityRelation.distinctSite => 'distinct_site',
      SiteIdentityRelation.unknown => 'unknown',
    };

String _methodName(SiteIdentityReconciliationMethod method) => switch (method) {
      SiteIdentityReconciliationMethod.officialCrossReference =>
        'official_cross_reference',
      SiteIdentityReconciliationMethod.officialSource => 'official_source',
      SiteIdentityReconciliationMethod.fieldObservation => 'field_observation',
      SiteIdentityReconciliationMethod.manualReview => 'manual_review',
    };

String _requiredText(Map<String, dynamic> row, String field) {
  final value = _optionalText(row[field]);
  if (value == null) throw FormatException('Missing required field $field.');
  return value;
}

String? _optionalText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

DateTime? _optionalDate(Object? value) {
  final text = _optionalText(value);
  return text == null ? null : DateTime.tryParse(text);
}

Map<String, String> _optionalMetadata(String key, Object? value) {
  final text = _optionalText(value);
  return text == null ? const {} : {key: text};
}
