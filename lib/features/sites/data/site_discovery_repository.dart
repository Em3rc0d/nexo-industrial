import 'dart:convert';

import 'package:flutter/services.dart';

import '../../knowledge/domain/knowledge.dart';
import '../domain/site.dart';
import '../domain/site_discovery.dart';
import 'asset_site_repository.dart';

class AssetSiteDiscoveryRepository {
  const AssetSiteDiscoveryRepository({
    this.overlayAssetPath = 'assets/data/sites.discovered.overlay.json',
    this.siteRepository = const AssetSiteRepository(),
  });

  final String overlayAssetPath;
  final AssetSiteRepository siteRepository;

  Future<SiteDiscoveryResult> loadSnapshot() async {
    final baseline = await siteRepository.loadSnapshot();
    final raw = await rootBundle.loadString(overlayAssetPath);
    final document = Map<String, dynamic>.from(jsonDecode(raw) as Map);

    if (document['format'] != 'nexo-industrial-site-discoveries') {
      throw const FormatException('Invalid site discovery overlay format.');
    }
    if (document['version'] != 1) {
      throw const FormatException('Unsupported site discovery overlay version.');
    }

    final records = (document['records'] as List<dynamic>? ?? const [])
        .map((row) => parseSiteDiscoveryRecord(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList(growable: false);

    return const SiteDiscoveryEngine().apply(baseline, records);
  }
}

class SiteDiscoveryEngine {
  const SiteDiscoveryEngine();

  SiteDiscoveryResult apply(
    SiteSnapshot baseline,
    List<SiteDiscoveryRecord> discoveries,
  ) {
    final sites = [...baseline.sites];
    final placements = [...baseline.placements];
    final gaps = [...baseline.gaps];
    final siteIds = sites.map((site) => site.id).toSet();
    final knownRucs = sites.map((site) => site.organizationRuc).toSet();
    final normalizedLabels = <String, Set<String>>{};

    for (final site in sites) {
      normalizedLabels
          .putIfAbsent(site.organizationRuc, () => <String>{})
          .add(_normalize(site.displayLabel));
    }

    final discoveryIds = <String>{};
    final claims = <KnowledgeClaim>[];
    final evidenceById = <String, EvidenceRef>{};

    for (final discovery in discoveries) {
      if (!discoveryIds.add(discovery.id)) {
        throw FormatException('Duplicate discovery id: ${discovery.id}');
      }
      if (!knownRucs.contains(discovery.organizationRuc)) {
        throw FormatException(
          'Discovery references unknown RUC: ${discovery.organizationRuc}',
        );
      }
      if (!discovery.siteId.startsWith('site:${discovery.organizationRuc}:')) {
        throw FormatException(
          'Discovery site/RUC mismatch: ${discovery.siteId}',
        );
      }
      if (!siteIds.add(discovery.siteId)) {
        throw FormatException('Duplicate site id: ${discovery.siteId}');
      }
      if (discovery.evidence.isEmpty) {
        throw FormatException(
          'Site discovery requires evidence: ${discovery.id}',
        );
      }

      final label = discovery.displayLabel.trim();
      if (label.isEmpty) {
        throw FormatException('Site discovery requires display label.');
      }
      final normalized = _normalize(label);
      final orgLabels = normalizedLabels.putIfAbsent(
        discovery.organizationRuc,
        () => <String>{},
      );
      if (!orgLabels.add(normalized)) {
        throw FormatException(
          'Site discovery duplicates an existing site label: ${discovery.id}',
        );
      }

      for (final evidence in discovery.evidence) {
        _validateEvidence(evidence, discovery.id);
        final existing = evidenceById[evidence.id];
        if (existing != null &&
            (existing.locator != evidence.locator ||
                existing.sourceType != evidence.sourceType)) {
          throw FormatException(
            'Conflicting site discovery evidence id: ${evidence.id}',
          );
        }
        evidenceById[evidence.id] = existing ?? evidence;
      }

      final claimId = 'claim:site:${discovery.siteId}:identity:${discovery.id}';
      sites.add(
        Site(
          id: discovery.siteId,
          organizationRuc: discovery.organizationRuc,
          displayLabel: label,
          function: discovery.function,
          identityBasis: SiteIdentityBasis.discoveredEvidence,
          operationalStatus: SiteOperationalStatus.unknown,
          sourceClaimId: claimId,
        ),
      );

      claims.add(
        KnowledgeClaim(
          id: claimId,
          subject: KnowledgeSubjectRef(
            type: KnowledgeSubjectType.site,
            id: discovery.siteId,
          ),
          predicate: 'site.identity',
          value: Map<String, Object?>.unmodifiable({
            'organization_ruc': discovery.organizationRuc,
            'display_label': label,
            'function': _siteFunctionName(discovery.function),
            'discovery_id': discovery.id,
          }),
          origin: _origin(discovery.method),
          temporalMode: KnowledgeTemporalMode.current,
          confidence: _confidence(discovery.method),
          asOf: discovery.discoveredAt,
          evidenceIds:
              discovery.evidence.map((item) => item.id).toList(growable: false),
          metadata: {
            'discovery_method': _methodName(discovery.method),
          },
        ),
      );

      gaps.add(
        KnowledgeGap(
          id: 'gap:site:${discovery.siteId}:placement',
          subject: KnowledgeSubjectRef(
            type: KnowledgeSubjectType.site,
            id: discovery.siteId,
          ),
          predicate: 'site.placement',
          reason: KnowledgeGapReason.unknown,
          identifiedAt: discovery.discoveredAt,
          metadata: const {
            'meaning':
                'Site identity is evidenced, but no coordinate placement has been verified.',
          },
        ),
      );
    }

    return SiteDiscoveryResult(
      snapshot: SiteSnapshot(
        sites: sites,
        placements: placements,
        gaps: gaps,
      ),
      discoveries: discoveries,
      claims: claims,
      evidence: evidenceById.values.toList(growable: false),
    );
  }
}

SiteDiscoveryRecord parseSiteDiscoveryRecord(Map<String, dynamic> row) {
  final id = _requiredText(row, 'id');
  final discoveredAt = DateTime.tryParse(_requiredText(row, 'discovered_at'));
  if (discoveredAt == null) {
    throw FormatException('Invalid discovered_at: $id');
  }

  final evidence = (row['evidence'] as List<dynamic>? ?? const [])
      .map((item) => _parseEvidence(
            Map<String, dynamic>.from(item as Map),
            discoveryId: id,
          ))
      .toList(growable: false);

  return SiteDiscoveryRecord(
    id: id,
    siteId: _requiredText(row, 'site_id'),
    organizationRuc: _requiredText(row, 'organization_ruc'),
    displayLabel: _requiredText(row, 'display_label'),
    function: _parseSiteFunction(_requiredText(row, 'site_function')),
    method: _parseMethod(_requiredText(row, 'method')),
    discoveredAt: discoveredAt,
    evidence: evidence,
  );
}

EvidenceRef _parseEvidence(
  Map<String, dynamic> row, {
  required String discoveryId,
}) {
  final sourceType = switch (_requiredText(row, 'source_type')) {
    'url' => EvidenceSourceType.url,
    'dataset' => EvidenceSourceType.dataset,
    'user_activity' => EvidenceSourceType.userActivity,
    _ => throw FormatException(
        'Unsupported discovery evidence source type: $discoveryId',
      ),
  };

  return EvidenceRef(
    id: _requiredText(row, 'id'),
    sourceType: sourceType,
    locator: _requiredText(row, 'locator'),
    reviewedAt: _optionalDate(row['reviewed_at']),
    summary: _optionalText(row['summary']),
    metadata: const {'knowledge_family': 'site_discovery'},
  );
}

void _validateEvidence(EvidenceRef evidence, String discoveryId) {
  if (evidence.sourceType == EvidenceSourceType.url) {
    final uri = Uri.tryParse(evidence.locator);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw FormatException(
        'Public discovery evidence must use HTTPS: $discoveryId',
      );
    }
  }
}

SiteDiscoveryMethod _parseMethod(String value) => switch (value) {
      'official_source' => SiteDiscoveryMethod.officialSource,
      'public_source' => SiteDiscoveryMethod.publicSource,
      'field_observation' => SiteDiscoveryMethod.fieldObservation,
      'manual_review' => SiteDiscoveryMethod.manualReview,
      _ => throw FormatException('Unsupported site discovery method: $value'),
    };

SiteFunction _parseSiteFunction(String value) => switch (value) {
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

KnowledgeOrigin _origin(SiteDiscoveryMethod method) => switch (method) {
      SiteDiscoveryMethod.fieldObservation => KnowledgeOrigin.observed,
      SiteDiscoveryMethod.officialSource || SiteDiscoveryMethod.publicSource =>
        KnowledgeOrigin.declared,
      SiteDiscoveryMethod.manualReview => KnowledgeOrigin.derived,
    };

KnowledgeConfidence _confidence(SiteDiscoveryMethod method) => switch (method) {
      SiteDiscoveryMethod.officialSource || SiteDiscoveryMethod.fieldObservation =>
        KnowledgeConfidence.high,
      SiteDiscoveryMethod.publicSource || SiteDiscoveryMethod.manualReview =>
        KnowledgeConfidence.medium,
    };

String _methodName(SiteDiscoveryMethod method) => switch (method) {
      SiteDiscoveryMethod.officialSource => 'official_source',
      SiteDiscoveryMethod.publicSource => 'public_source',
      SiteDiscoveryMethod.fieldObservation => 'field_observation',
      SiteDiscoveryMethod.manualReview => 'manual_review',
    };

String _siteFunctionName(SiteFunction value) => switch (value) {
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

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');

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
