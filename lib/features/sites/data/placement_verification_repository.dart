import 'dart:convert';

import 'package:flutter/services.dart';

import '../../knowledge/domain/knowledge.dart';
import '../domain/placement_verification.dart';
import '../domain/site.dart';
import 'site_identity_reconciliation_repository.dart';

class AssetPlacementVerificationRepository {
  const AssetPlacementVerificationRepository({
    this.overlayAssetPath = 'assets/data/site.placement.verified.overlay.json',
    this.siteIdentityReconciliationRepository =
        const AssetSiteIdentityReconciliationRepository(),
  });

  final String overlayAssetPath;
  final AssetSiteIdentityReconciliationRepository
      siteIdentityReconciliationRepository;

  Future<PlacementVerificationResult> loadSnapshot() async {
    final reconciliation =
        await siteIdentityReconciliationRepository.loadSnapshot();
    final raw = await rootBundle.loadString(overlayAssetPath);
    final document = Map<String, dynamic>.from(jsonDecode(raw) as Map);

    if (document['format'] != 'nexo-industrial-placement-verifications') {
      throw const FormatException('Invalid placement verification overlay format.');
    }
    if (document['version'] != 1) {
      throw const FormatException(
        'Unsupported placement verification overlay version.',
      );
    }

    final records = (document['records'] as List<dynamic>? ?? const [])
        .map(
          (row) => parsePlacementVerificationRecord(
            Map<String, dynamic>.from(row as Map),
          ),
        )
        .toList(growable: false);

    return const PlacementVerificationEngine().apply(
      reconciliation.snapshot,
      records,
    );
  }
}

class PlacementVerificationEngine {
  const PlacementVerificationEngine();

  PlacementVerificationResult apply(
    SiteSnapshot baseline,
    List<PlacementVerificationRecord> verifications,
  ) {
    final sitesById = {
      for (final site in baseline.sites) site.id: site,
    };
    final placements = [...baseline.placements];
    final gaps = [...baseline.gaps];
    final ids = <String>{};
    final verifiedSiteIds = <String>{};
    final evidenceById = <String, EvidenceRef>{};
    final claims = <KnowledgeClaim>[];

    for (final verification in verifications) {
      if (!ids.add(verification.id)) {
        throw FormatException(
          'Duplicate placement verification id: ${verification.id}',
        );
      }
      if (!verifiedSiteIds.add(verification.siteId)) {
        throw FormatException(
          'Only one current placement verification per Site is allowed: '
          '${verification.siteId}',
        );
      }
      if (!sitesById.containsKey(verification.siteId)) {
        throw FormatException(
          'Placement verification references unknown Site: '
          '${verification.siteId}',
        );
      }
      if (verification.evidence.isEmpty) {
        throw FormatException(
          'Placement verification requires evidence: ${verification.id}',
        );
      }
      if (!_validCoordinate(
        verification.latitude,
        verification.longitude,
      )) {
        throw FormatException(
          'Placement verification has invalid coordinates: '
          '${verification.id}',
        );
      }
      if (verification.navigationEligible &&
          !verification.nearbyRankingEligible) {
        throw FormatException(
          'Navigation eligibility cannot bypass nearby eligibility: '
          '${verification.id}',
        );
      }
      if (verification.quality == PlacementQuality.propertyReference &&
          (verification.nearbyRankingEligible ||
              verification.navigationEligible)) {
        throw FormatException(
          'Property-reference placement cannot enable proximity/navigation: '
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
            'Conflicting placement evidence id: ${evidence.id}',
          );
        }
        evidenceById[evidence.id] = existing ?? evidence;
      }

      final currentForSite = placements
          .where((item) => item.siteId == verification.siteId)
          .toList(growable: false);

      if (currentForSite.isNotEmpty) {
        final supersedes = verification.supersedesPlacementId;
        if (supersedes == null ||
            currentForSite.every((item) => item.id != supersedes)) {
          throw FormatException(
            'Replacing an existing placement requires explicit supersedes ID: '
            '${verification.id}',
          );
        }
        placements.removeWhere(
          (item) =>
              item.siteId == verification.siteId &&
              item.id == verification.supersedesPlacementId,
        );
      } else if (verification.supersedesPlacementId != null) {
        throw FormatException(
          'Cannot supersede missing placement: ${verification.id}',
        );
      }

      final claimId =
          'claim:site:${verification.siteId}:placement:${verification.id}';
      final placementId =
          'placement:${verification.siteId}:verified:${verification.id}';

      placements.add(
        Placement(
          id: placementId,
          siteId: verification.siteId,
          latitude: verification.latitude,
          longitude: verification.longitude,
          quality: verification.quality,
          confidence: verification.confidence,
          mapDisplayEligible: verification.mapDisplayEligible,
          nearbyRankingEligible: verification.nearbyRankingEligible,
          navigationEligible: verification.navigationEligible,
          sourceClaimId: claimId,
          evidenceIds: List.unmodifiable(
            verification.evidence.map((item) => item.id),
          ),
          address: verification.address,
          district: verification.district,
          province: verification.province,
          department: verification.department,
          asOf: verification.verifiedAt,
        ),
      );

      claims.add(
        KnowledgeClaim(
          id: claimId,
          subject: KnowledgeSubjectRef(
            type: KnowledgeSubjectType.site,
            id: verification.siteId,
          ),
          predicate: 'site.placement',
          value: Map<String, Object?>.unmodifiable({
            'latitude': verification.latitude,
            'longitude': verification.longitude,
            'quality': _qualityName(verification.quality),
            'map_display_eligible': verification.mapDisplayEligible,
            'nearby_ranking_eligible': verification.nearbyRankingEligible,
            'navigation_eligible': verification.navigationEligible,
          }),
          origin: _origin(verification.method),
          temporalMode: KnowledgeTemporalMode.current,
          confidence: verification.confidence,
          asOf: verification.verifiedAt,
          evidenceIds:
              verification.evidence.map((item) => item.id).toList(growable: false),
          metadata: {
            'verification_method': _methodName(verification.method),
            ..._optionalMetadata(
              'source_crs',
              verification.sourceCoordinateReferenceSystem,
            ),
            ..._optionalMetadata('notes', verification.notes),
          },
        ),
      );

      gaps.removeWhere(
        (gap) =>
            gap.subject.type == KnowledgeSubjectType.site &&
            gap.subject.id == verification.siteId &&
            gap.predicate == 'site.placement',
      );
    }

    return PlacementVerificationResult(
      snapshot: SiteSnapshot(
        sites: baseline.sites,
        placements: placements,
        gaps: gaps,
      ),
      verifications: verifications,
      claims: claims,
      evidence: evidenceById.values.toList(growable: false),
    );
  }
}

PlacementVerificationRecord parsePlacementVerificationRecord(
  Map<String, dynamic> row,
) {
  final id = _requiredText(row, 'id');
  final verifiedAt = DateTime.tryParse(_requiredText(row, 'verified_at'));
  if (verifiedAt == null) {
    throw FormatException('Invalid verified_at: $id');
  }

  final evidence = (row['evidence'] as List<dynamic>? ?? const [])
      .map(
        (item) => _parseEvidence(
          Map<String, dynamic>.from(item as Map),
          verificationId: id,
        ),
      )
      .toList(growable: false);

  return PlacementVerificationRecord(
    id: id,
    siteId: _requiredText(row, 'site_id'),
    latitude: _requiredDouble(row, 'latitude'),
    longitude: _requiredDouble(row, 'longitude'),
    quality: _parseQuality(_requiredText(row, 'quality')),
    confidence: _parseConfidence(_requiredText(row, 'confidence')),
    method: _parseMethod(_requiredText(row, 'method')),
    verifiedAt: verifiedAt,
    mapDisplayEligible: row['map_display_eligible'] as bool? ?? true,
    nearbyRankingEligible: row['nearby_ranking_eligible'] as bool? ?? false,
    navigationEligible: row['navigation_eligible'] as bool? ?? false,
    evidence: evidence,
    address: _optionalText(row['address']),
    district: _optionalText(row['district']),
    province: _optionalText(row['province']),
    department: _optionalText(row['department']),
    supersedesPlacementId: _optionalText(row['supersedes_placement_id']),
    sourceCoordinateReferenceSystem: _optionalText(row['source_crs']),
    notes: _optionalText(row['notes']),
  );
}

EvidenceRef _parseEvidence(
  Map<String, dynamic> row, {
  required String verificationId,
}) {
  final sourceType = switch (_requiredText(row, 'source_type')) {
    'url' => EvidenceSourceType.url,
    'dataset' => EvidenceSourceType.dataset,
    'user_activity' => EvidenceSourceType.userActivity,
    _ => throw FormatException(
        'Unsupported placement evidence type: $verificationId',
      ),
  };

  return EvidenceRef(
    id: _requiredText(row, 'id'),
    sourceType: sourceType,
    locator: _requiredText(row, 'locator'),
    reviewedAt: _optionalDate(row['reviewed_at']),
    observedAt: _optionalDate(row['observed_at']),
    summary: _optionalText(row['summary']),
    metadata: const {'knowledge_family': 'placement_verification'},
  );
}

void _validateEvidence(EvidenceRef evidence, String verificationId) {
  if (evidence.sourceType == EvidenceSourceType.url) {
    final uri = Uri.tryParse(evidence.locator);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw FormatException(
        'Public placement evidence must use HTTPS: $verificationId',
      );
    }
  }
}

PlacementQuality _parseQuality(String value) => switch (value) {
      'exact_address' => PlacementQuality.exactAddress,
      'address_reference' => PlacementQuality.addressReference,
      'property_reference' => PlacementQuality.propertyReference,
      'interpolated_address' => PlacementQuality.interpolatedAddress,
      'street_reference' => PlacementQuality.streetReference,
      'district_reference' => PlacementQuality.districtReference,
      _ => throw FormatException('Unsupported placement quality: $value'),
    };

KnowledgeConfidence _parseConfidence(String value) => switch (value) {
      'high' => KnowledgeConfidence.high,
      'medium' => KnowledgeConfidence.medium,
      'low' => KnowledgeConfidence.low,
      'very_low' => KnowledgeConfidence.veryLow,
      'unknown' => KnowledgeConfidence.unknown,
      _ => throw FormatException('Unsupported placement confidence: $value'),
    };

PlacementVerificationMethod _parseMethod(String value) => switch (value) {
      'official_coordinates' => PlacementVerificationMethod.officialCoordinates,
      'field_observation' => PlacementVerificationMethod.fieldObservation,
      'public_geocoder' => PlacementVerificationMethod.publicGeocoder,
      'manual_review' => PlacementVerificationMethod.manualReview,
      _ => throw FormatException('Unsupported placement method: $value'),
    };

KnowledgeOrigin _origin(PlacementVerificationMethod value) => switch (value) {
      PlacementVerificationMethod.fieldObservation => KnowledgeOrigin.observed,
      PlacementVerificationMethod.officialCoordinates =>
        KnowledgeOrigin.authoritative,
      PlacementVerificationMethod.publicGeocoder =>
        KnowledgeOrigin.derived,
      PlacementVerificationMethod.manualReview => KnowledgeOrigin.derived,
    };

String _methodName(PlacementVerificationMethod value) => switch (value) {
      PlacementVerificationMethod.officialCoordinates => 'official_coordinates',
      PlacementVerificationMethod.fieldObservation => 'field_observation',
      PlacementVerificationMethod.publicGeocoder => 'public_geocoder',
      PlacementVerificationMethod.manualReview => 'manual_review',
    };

String _qualityName(PlacementQuality value) => switch (value) {
      PlacementQuality.exactAddress => 'exact_address',
      PlacementQuality.addressReference => 'address_reference',
      PlacementQuality.propertyReference => 'property_reference',
      PlacementQuality.interpolatedAddress => 'interpolated_address',
      PlacementQuality.streetReference => 'street_reference',
      PlacementQuality.districtReference => 'district_reference',
    };

bool _validCoordinate(double latitude, double longitude) =>
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180;

String _requiredText(Map<String, dynamic> row, String field) {
  final value = _optionalText(row[field]);
  if (value == null) throw FormatException('Missing required field $field.');
  return value;
}

double _requiredDouble(Map<String, dynamic> row, String field) {
  final value = row[field];
  if (value is num) return value.toDouble();
  final parsed = double.tryParse(value?.toString() ?? '');
  if (parsed == null) throw FormatException('Invalid numeric field $field.');
  return parsed;
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
