import 'dart:convert';

import 'package:flutter/services.dart';

import '../../knowledge/domain/knowledge.dart';
import '../domain/property_facility.dart';
import '../domain/site.dart';
import 'site_identity_reconciliation_repository.dart';

class AssetPropertyFacilityRepository {
  const AssetPropertyFacilityRepository({
    this.overlayAssetPath = 'assets/data/property.facility.overlay.json',
    this.siteIdentityRepository = const AssetSiteIdentityReconciliationRepository(),
  });

  final String overlayAssetPath;
  final AssetSiteIdentityReconciliationRepository siteIdentityRepository;

  Future<PropertyFacilitySnapshot> loadSnapshot() async {
    final activeSites = await siteIdentityRepository.loadSnapshot();
    final raw = await rootBundle.loadString(overlayAssetPath);
    final document = Map<String, dynamic>.from(jsonDecode(raw) as Map);

    if (document['format'] != 'nexo-industrial-property-facility-overlay') {
      throw const FormatException('Invalid property/facility overlay format.');
    }
    if (document['version'] != 1) {
      throw const FormatException('Unsupported property/facility overlay version.');
    }

    final evidenceById = <String, EvidenceRef>{};
    final properties = <PropertyRecord>[];
    final facilities = <OperationalFacility>[];
    final assets = <PhysicalAsset>[];
    final placements = <EntityPlacement>[];
    final relationships = <PropertySiteRelationship>[];
    final claims = <KnowledgeClaim>[];

    for (final rawProperty in document['properties'] as List<dynamic>? ?? const []) {
      final row = Map<String, dynamic>.from(rawProperty as Map);
      final evidence = _parseEvidenceList(row['evidence'], evidenceById);
      properties.add(PropertyRecord(
        id: _requiredText(row, 'id'),
        organizationRuc: _requiredText(row, 'organization_ruc'),
        parcelLabel: _requiredText(row, 'parcel_label'),
        tenure: _parseTenure(_requiredText(row, 'tenure')),
        tenureValidUntil: _optionalDate(row['tenure_valid_until']),
        evidence: evidence,
        notes: _optionalText(row['notes']),
      ));
    }

    final propertyIds = properties.map((item) => item.id).toSet();
    for (final rawFacility in document['facilities'] as List<dynamic>? ?? const []) {
      final row = Map<String, dynamic>.from(rawFacility as Map);
      final propertyId = _requiredText(row, 'property_id');
      if (!propertyIds.contains(propertyId)) {
        throw FormatException('Facility references unknown Property: ' + propertyId);
      }
      final evidence = _parseEvidenceList(row['evidence'], evidenceById);
      facilities.add(OperationalFacility(
        id: _requiredText(row, 'id'),
        organizationRuc: _requiredText(row, 'organization_ruc'),
        propertyId: propertyId,
        type: _parseFacilityType(_requiredText(row, 'type')),
        displayLabel: _requiredText(row, 'display_label'),
        evidence: evidence,
      ));
    }

    final facilityIds = facilities.map((item) => item.id).toSet();
    for (final rawAsset in document['assets'] as List<dynamic>? ?? const []) {
      final row = Map<String, dynamic>.from(rawAsset as Map);
      final facilityId = _requiredText(row, 'facility_id');
      if (!facilityIds.contains(facilityId)) {
        throw FormatException('Asset references unknown Facility: ' + facilityId);
      }
      assets.add(PhysicalAsset(
        id: _requiredText(row, 'id'),
        facilityId: facilityId,
        displayLabel: _requiredText(row, 'display_label'),
        assetType: _requiredText(row, 'asset_type'),
      ));
    }

    final assetIds = assets.map((item) => item.id).toSet();
    for (final rawPlacement in document['placements'] as List<dynamic>? ?? const []) {
      final row = Map<String, dynamic>.from(rawPlacement as Map);
      final type = _parseEntityType(_requiredText(row, 'entity_type'));
      final entityId = _requiredText(row, 'entity_id');
      final exists = switch (type) {
        SpatialEntityType.site => activeSites.snapshot.siteById(entityId) != null,
        SpatialEntityType.property => propertyIds.contains(entityId),
        SpatialEntityType.operationalFacility => facilityIds.contains(entityId),
        SpatialEntityType.asset => assetIds.contains(entityId),
      };
      if (!exists) {
        throw FormatException('Placement references unknown typed entity: ' + entityId);
      }

      final evidence = _parseEvidenceList(row['evidence'], evidenceById);
      final placement = EntityPlacement(
        id: _requiredText(row, 'id'),
        entityType: type,
        entityId: entityId,
        latitude: (row['latitude'] as num).toDouble(),
        longitude: (row['longitude'] as num).toDouble(),
        quality: PlacementQuality.fromKnowledgeValue(row['quality']),
        confidence: _parseConfidence(_requiredText(row, 'confidence')),
        sourceClaimId: _requiredText(row, 'source_claim_id'),
        evidenceIds: evidence.map((item) => item.id).toList(growable: false),
        sourceCoordinateReferenceSystem:
            _optionalText(row['source_coordinate_reference_system']),
        asOf: _optionalDate(row['as_of']),
      );
      if (!placement.hasValidCoordinates) {
        throw FormatException('Invalid typed Placement coordinates: ' + placement.id);
      }
      placements.add(placement);
    }

    for (final rawRelationship
        in document['property_site_relationships'] as List<dynamic>? ?? const []) {
      final row = Map<String, dynamic>.from(rawRelationship as Map);
      final propertyId = _requiredText(row, 'property_id');
      final siteId = _requiredText(row, 'site_id');
      if (!propertyIds.contains(propertyId)) {
        throw FormatException('Relationship references unknown Property: ' + propertyId);
      }
      if (activeSites.snapshot.siteById(siteId) == null) {
        throw FormatException('Relationship must target active canonical Site: ' + siteId);
      }

      final evidence = _parseEvidenceList(row['evidence'], evidenceById);
      final relationship = PropertySiteRelationship(
        id: _requiredText(row, 'id'),
        propertyId: propertyId,
        siteId: siteId,
        relation: _parsePropertyRelation(_requiredText(row, 'relation')),
        operationallyRelated: row['operationally_related'] == true,
        confidence: _parseConfidence(_requiredText(row, 'confidence')),
        reviewedAt: _requiredDate(row, 'reviewed_at'),
        evidence: evidence,
        rationale: _optionalText(row['rationale']),
      );
      relationships.add(relationship);

      claims.add(KnowledgeClaim(
        id: 'claim:property-site:' + relationship.id,
        subject: KnowledgeSubjectRef(
          type: KnowledgeSubjectType.property,
          id: relationship.propertyId,
        ),
        predicate: 'property.site_relation',
        value: {
          'site_id': relationship.siteId,
          'relation': _propertyRelationName(relationship.relation),
          'operationally_related': relationship.operationallyRelated,
        },
        origin: KnowledgeOrigin.derived,
        temporalMode: KnowledgeTemporalMode.current,
        confidence: relationship.confidence,
        asOf: relationship.reviewedAt,
        evidenceIds:
            relationship.evidence.map((item) => item.id).toList(growable: false),
      ));
    }

    for (final facility in facilities) {
      claims.add(KnowledgeClaim(
        id: 'claim:facility:' + facility.id,
        subject: KnowledgeSubjectRef(
          type: KnowledgeSubjectType.operationalFacility,
          id: facility.id,
        ),
        predicate: 'facility.exists',
        value: {
          'property_id': facility.propertyId,
          'type': _facilityTypeName(facility.type),
        },
        origin: KnowledgeOrigin.authoritative,
        temporalMode: KnowledgeTemporalMode.current,
        confidence: KnowledgeConfidence.high,
        evidenceIds: facility.evidence.map((item) => item.id).toList(growable: false),
      ));
    }

    return PropertyFacilitySnapshot(
      properties: properties,
      facilities: facilities,
      assets: assets,
      placements: placements,
      relationships: relationships,
      claims: claims,
      evidence: evidenceById.values.toList(growable: false),
    );
  }
}

List<EvidenceRef> _parseEvidenceList(
  Object? raw,
  Map<String, EvidenceRef> evidenceById,
) {
  final rows = raw as List<dynamic>? ?? const [];
  if (rows.isEmpty) {
    throw const FormatException('Property/facility evidence is required.');
  }
  final parsed = <EvidenceRef>[];
  for (final item in rows) {
    final row = Map<String, dynamic>.from(item as Map);
    final sourceType = switch (_requiredText(row, 'source_type')) {
      'url' => EvidenceSourceType.url,
      'dataset' => EvidenceSourceType.dataset,
      'user_activity' => EvidenceSourceType.userActivity,
      _ => throw const FormatException('Unsupported evidence source type.'),
    };
    final locator = _requiredText(row, 'locator');
    if (sourceType == EvidenceSourceType.url) {
      final uri = Uri.tryParse(locator);
      if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
        throw const FormatException('Public evidence must use HTTPS.');
      }
    }
    final evidence = EvidenceRef(
      id: _requiredText(row, 'id'),
      sourceType: sourceType,
      locator: locator,
      reviewedAt: _optionalDate(row['reviewed_at']),
      observedAt: _optionalDate(row['observed_at']),
      summary: _optionalText(row['summary']),
      metadata: const {'knowledge_family': 'property_facility'},
    );
    final existing = evidenceById[evidence.id];
    if (existing != null &&
        (existing.locator != evidence.locator ||
            existing.sourceType != evidence.sourceType)) {
      throw FormatException('Conflicting evidence id: ' + evidence.id);
    }
    evidenceById[evidence.id] = existing ?? evidence;
    parsed.add(evidence);
  }
  return parsed;
}

PropertyTenure _parseTenure(String value) => switch (value) {
      'unknown' => PropertyTenure.unknown,
      'owned' => PropertyTenure.owned,
      'leased' => PropertyTenure.leased,
      'occupied' => PropertyTenure.occupied,
      _ => throw FormatException('Unsupported Property tenure: ' + value),
    };

OperationalFacilityType _parseFacilityType(String value) => switch (value) {
      'unknown' => OperationalFacilityType.unknown,
      'headquarters' => OperationalFacilityType.headquarters,
      'office' => OperationalFacilityType.office,
      'plant' => OperationalFacilityType.plant,
      'mine' => OperationalFacilityType.mine,
      'warehouse' => OperationalFacilityType.warehouse,
      'workshop' => OperationalFacilityType.workshop,
      'shipyard' => OperationalFacilityType.shipyard,
      'terminal' => OperationalFacilityType.terminal,
      'project_site' => OperationalFacilityType.projectSite,
      _ => throw FormatException('Unsupported Facility type: ' + value),
    };

SpatialEntityType _parseEntityType(String value) => switch (value) {
      'site' => SpatialEntityType.site,
      'property' => SpatialEntityType.property,
      'operational_facility' => SpatialEntityType.operationalFacility,
      'asset' => SpatialEntityType.asset,
      _ => throw FormatException('Unsupported spatial entity type: ' + value),
    };

PropertyRelation _parsePropertyRelation(String value) => switch (value) {
      'part_of_site' => PropertyRelation.partOfSite,
      'adjacent_property' => PropertyRelation.adjacentProperty,
      'distinct_property' => PropertyRelation.distinctProperty,
      'unknown' => PropertyRelation.unknown,
      _ => throw FormatException('Unsupported Property relation: ' + value),
    };

KnowledgeConfidence _parseConfidence(String value) => switch (value) {
      'high' => KnowledgeConfidence.high,
      'medium' => KnowledgeConfidence.medium,
      'low' => KnowledgeConfidence.low,
      'very_low' => KnowledgeConfidence.veryLow,
      'unknown' => KnowledgeConfidence.unknown,
      _ => throw FormatException('Unsupported confidence: ' + value),
    };

String _propertyRelationName(PropertyRelation value) => switch (value) {
      PropertyRelation.partOfSite => 'part_of_site',
      PropertyRelation.adjacentProperty => 'adjacent_property',
      PropertyRelation.distinctProperty => 'distinct_property',
      PropertyRelation.unknown => 'unknown',
    };

String _facilityTypeName(OperationalFacilityType value) => switch (value) {
      OperationalFacilityType.unknown => 'unknown',
      OperationalFacilityType.headquarters => 'headquarters',
      OperationalFacilityType.office => 'office',
      OperationalFacilityType.plant => 'plant',
      OperationalFacilityType.mine => 'mine',
      OperationalFacilityType.warehouse => 'warehouse',
      OperationalFacilityType.workshop => 'workshop',
      OperationalFacilityType.shipyard => 'shipyard',
      OperationalFacilityType.terminal => 'terminal',
      OperationalFacilityType.projectSite => 'project_site',
    };

String _requiredText(Map<String, dynamic> row, String field) {
  final value = _optionalText(row[field]);
  if (value == null) throw FormatException('Missing required field ' + field + '.');
  return value;
}

DateTime _requiredDate(Map<String, dynamic> row, String field) {
  final value = _optionalDate(row[field]);
  if (value == null) throw FormatException('Invalid required date ' + field + '.');
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
