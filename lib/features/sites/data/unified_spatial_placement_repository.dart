import '../domain/property_facility.dart';
import '../domain/unified_spatial.dart';
import 'property_facility_repository.dart';
import 'site_identity_reconciliation_repository.dart';

class UnifiedSpatialPlacementRepository {
  const UnifiedSpatialPlacementRepository({
    this.siteIdentityRepository =
        const AssetSiteIdentityReconciliationRepository(),
    this.propertyFacilityRepository = const AssetPropertyFacilityRepository(),
  });

  final AssetSiteIdentityReconciliationRepository siteIdentityRepository;
  final AssetPropertyFacilityRepository propertyFacilityRepository;

  Future<UnifiedSpatialSnapshot> loadSnapshot() async {
    final activeSites = await siteIdentityRepository.loadSnapshot();
    final propertyFacility = await propertyFacilityRepository.loadSnapshot();

    final placements = <EntityPlacement>[];
    final ids = <String>{};

    for (final legacy in activeSites.snapshot.placements) {
      final unified = EntityPlacement(
        id: legacy.id,
        entityType: SpatialEntityType.site,
        entityId: legacy.siteId,
        latitude: legacy.latitude,
        longitude: legacy.longitude,
        quality: legacy.quality,
        confidence: legacy.confidence,
        mapDisplayEligible: legacy.mapDisplayEligible,
        nearbyRankingEligible: legacy.nearbyRankingEligible,
        navigationEligible: legacy.navigationEligible,
        sourceClaimId: legacy.sourceClaimId,
        evidenceIds: List.unmodifiable(legacy.evidenceIds),
        address: legacy.address,
        district: legacy.district,
        province: legacy.province,
        department: legacy.department,
        asOf: legacy.asOf,
      );
      _validatePlacement(unified);
      if (!ids.add(unified.id)) {
        throw FormatException('Duplicate unified Placement id: ${unified.id}');
      }
      placements.add(unified);
    }

    for (final placement in propertyFacility.placements) {
      _validatePlacement(placement);
      if (!ids.add(placement.id)) {
        throw FormatException('Duplicate unified Placement id: ${placement.id}');
      }
      placements.add(placement);
    }

    final activeSiteIds =
        activeSites.snapshot.sites.map((site) => site.id).toSet();
    for (final placement in placements.where(
      (item) => item.entityType == SpatialEntityType.site,
    )) {
      if (!activeSiteIds.contains(placement.entityId)) {
        throw FormatException(
          'Unified Site Placement targets non-canonical Site: ${placement.id}',
        );
      }
    }

    return UnifiedSpatialSnapshot(
      placements: placements,
      legacySitePlacementCount: activeSites.snapshot.placements.length,
      nonSitePlacementCount: propertyFacility.placements.length,
    );
  }
}

void _validatePlacement(EntityPlacement placement) {
  if (!placement.hasValidCoordinates) {
    throw FormatException('Invalid unified Placement coordinates: ${placement.id}');
  }
  if (placement.navigationEligible && !placement.nearbyRankingEligible) {
    throw FormatException(
      'Navigation cannot bypass nearby ranking eligibility: ${placement.id}',
    );
  }
  if (placement.quality.name == 'propertyReference' &&
      (placement.nearbyRankingEligible || placement.navigationEligible)) {
    throw FormatException(
      'Property reference Placement cannot be actionable: ${placement.id}',
    );
  }
  if (!placement.mapDisplayEligible &&
      (placement.nearbyRankingEligible || placement.navigationEligible)) {
    throw FormatException(
      'Hidden Placement cannot be actionable: ${placement.id}',
    );
  }
}
