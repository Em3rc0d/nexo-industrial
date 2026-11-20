import '../../knowledge/domain/knowledge.dart';
import 'site.dart';

enum PropertyRelation { partOfSite, adjacentProperty, distinctProperty, unknown }
enum PropertyTenure { unknown, owned, leased, occupied }
enum OperationalFacilityType {
  unknown, headquarters, office, plant, mine, warehouse, workshop, shipyard,
  terminal, projectSite,
}
enum SpatialEntityType { site, property, operationalFacility, asset }

class PropertyRecord {
  const PropertyRecord({
    required this.id,
    required this.organizationRuc,
    required this.parcelLabel,
    required this.tenure,
    required this.evidence,
    this.tenureValidUntil,
    this.notes,
  });
  final String id;
  final String organizationRuc;
  final String parcelLabel;
  final PropertyTenure tenure;
  final DateTime? tenureValidUntil;
  final List<EvidenceRef> evidence;
  final String? notes;
}

class OperationalFacility {
  const OperationalFacility({
    required this.id,
    required this.organizationRuc,
    required this.propertyId,
    required this.type,
    required this.displayLabel,
    required this.evidence,
  });
  final String id;
  final String organizationRuc;
  final String propertyId;
  final OperationalFacilityType type;
  final String displayLabel;
  final List<EvidenceRef> evidence;
}

class PhysicalAsset {
  const PhysicalAsset({
    required this.id,
    required this.facilityId,
    required this.displayLabel,
    required this.assetType,
  });
  final String id;
  final String facilityId;
  final String displayLabel;
  final String assetType;
}

class EntityPlacement {
  const EntityPlacement({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.latitude,
    required this.longitude,
    required this.quality,
    required this.confidence,
    required this.mapDisplayEligible,
    required this.nearbyRankingEligible,
    required this.navigationEligible,
    required this.sourceClaimId,
    required this.evidenceIds,
    this.address,
    this.district,
    this.province,
    this.department,
    this.sourceCoordinateReferenceSystem,
    this.asOf,
  });
  final String id;
  final SpatialEntityType entityType;
  final String entityId;
  final double latitude;
  final double longitude;
  final PlacementQuality quality;
  final KnowledgeConfidence confidence;
  final bool mapDisplayEligible;
  final bool nearbyRankingEligible;
  final bool navigationEligible;
  final String sourceClaimId;
  final List<String> evidenceIds;
  final String? address;
  final String? district;
  final String? province;
  final String? department;
  final String? sourceCoordinateReferenceSystem;
  final DateTime? asOf;

  bool get hasValidCoordinates =>
      latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
}

class PropertySiteRelationship {
  const PropertySiteRelationship({
    required this.id,
    required this.propertyId,
    required this.siteId,
    required this.relation,
    required this.operationallyRelated,
    required this.confidence,
    required this.reviewedAt,
    required this.evidence,
    this.rationale,
  });
  final String id;
  final String propertyId;
  final String siteId;
  final PropertyRelation relation;
  final bool operationallyRelated;
  final KnowledgeConfidence confidence;
  final DateTime reviewedAt;
  final List<EvidenceRef> evidence;
  final String? rationale;
}

class PropertyFacilitySnapshot {
  PropertyFacilitySnapshot({
    required List<PropertyRecord> properties,
    required List<OperationalFacility> facilities,
    required List<PhysicalAsset> assets,
    required List<EntityPlacement> placements,
    required List<PropertySiteRelationship> relationships,
    required List<KnowledgeClaim> claims,
    required List<EvidenceRef> evidence,
  })  : properties = List.unmodifiable(properties),
        facilities = List.unmodifiable(facilities),
        assets = List.unmodifiable(assets),
        placements = List.unmodifiable(placements),
        relationships = List.unmodifiable(relationships),
        claims = List.unmodifiable(claims),
        evidence = List.unmodifiable(evidence);

  final List<PropertyRecord> properties;
  final List<OperationalFacility> facilities;
  final List<PhysicalAsset> assets;
  final List<EntityPlacement> placements;
  final List<PropertySiteRelationship> relationships;
  final List<KnowledgeClaim> claims;
  final List<EvidenceRef> evidence;
}
