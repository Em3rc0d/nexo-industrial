import '../../knowledge/domain/knowledge.dart';

enum SiteFunction {
  unknown,
  headquarters,
  office,
  plant,
  mine,
  warehouse,
  workshop,
  shipyard,
  terminal,
  projectSite,
}

enum SiteIdentityBasis {
  verifiedHeadquartersAddress,
  fiscalAddress,
  geographicReference,
  discoveredEvidence,
}

enum SiteOperationalStatus {
  unknown,
  confirmedOperational,
  confirmedNotOperational,
}

enum PlacementQuality {
  exactAddress,
  addressReference,
  propertyReference,
  interpolatedAddress,
  streetReference,
  districtReference;

  static PlacementQuality fromKnowledgeValue(Object? value) {
    return switch (value?.toString()) {
      'exact_address' => PlacementQuality.exactAddress,
      'address_reference' => PlacementQuality.addressReference,
      'property_reference' => PlacementQuality.propertyReference,
      'interpolated_address' => PlacementQuality.interpolatedAddress,
      'street_reference' => PlacementQuality.streetReference,
      'district_reference' => PlacementQuality.districtReference,
      _ => throw FormatException('Unknown placement quality: $value'),
    };
  }
}

class Site {
  const Site({
    required this.id,
    required this.organizationRuc,
    required this.displayLabel,
    required this.function,
    required this.identityBasis,
    required this.operationalStatus,
    required this.sourceClaimId,
  });

  final String id;
  final String organizationRuc;
  final String displayLabel;

  /// Functional interpretation of the site. This never implies operational
  /// confirmation by itself.
  final SiteFunction function;

  /// Why this reference site exists in the current projection.
  final SiteIdentityBasis identityBasis;

  /// Current Nexo data does not prove that a registered or HQ address is an
  /// operating industrial site, so the default projection remains unknown.
  final SiteOperationalStatus operationalStatus;

  final String sourceClaimId;

  bool get isOperationallyConfirmed =>
      operationalStatus == SiteOperationalStatus.confirmedOperational;
}

class Placement {
  const Placement({
    required this.id,
    required this.siteId,
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
    this.asOf,
  });

  final String id;
  final String siteId;
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
  final DateTime? asOf;

  bool get hasValidCoordinates =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

class SiteSnapshot {
  SiteSnapshot({
    required List<Site> sites,
    required List<Placement> placements,
    required List<KnowledgeGap> gaps,
  })  : sites = List.unmodifiable(sites),
        placements = List.unmodifiable(placements),
        gaps = List.unmodifiable(gaps);

  final List<Site> sites;
  final List<Placement> placements;
  final List<KnowledgeGap> gaps;

  Site? siteById(String id) {
    for (final site in sites) {
      if (site.id == id) return site;
    }
    return null;
  }

  Iterable<Site> sitesForOrganization(String ruc) =>
      sites.where((site) => site.organizationRuc == ruc);

  Iterable<Placement> placementsForSite(String siteId) =>
      placements.where((placement) => placement.siteId == siteId);
}
