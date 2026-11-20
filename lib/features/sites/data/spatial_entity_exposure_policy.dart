import '../domain/property_facility.dart';
import '../domain/spatial_exposure.dart';

class SpatialEntityExposurePolicy {
  const SpatialEntityExposurePolicy();

  SpatialExposureDecision decide(
    EntityPlacement placement,
    SpatialExposureSurface surface,
  ) {
    return switch (surface) {
      SpatialExposureSurface.commercialMap => _commercialMap(placement),
      SpatialExposureSurface.companyDetail => _companyDetail(placement),
      SpatialExposureSurface.nearbyRanking => _nearbyRanking(placement),
      SpatialExposureSurface.navigation => _navigation(placement),
    };
  }

  SpatialExposureDecision _commercialMap(EntityPlacement placement) {
    if (placement.entityType != SpatialEntityType.site) {
      return _hidden(
        placement,
        SpatialExposureSurface.commercialMap,
        'Only Site entities may be commercial map markers in CONTRACT 029.',
      );
    }
    if (!placement.mapDisplayEligible) {
      return _hidden(
        placement,
        SpatialExposureSurface.commercialMap,
        'Placement is not eligible for map display.',
      );
    }
    return _primary(
      placement,
      SpatialExposureSurface.commercialMap,
      'Canonical Site with map-display eligibility.',
    );
  }

  SpatialExposureDecision _companyDetail(EntityPlacement placement) {
    if (placement.entityType == SpatialEntityType.site &&
        placement.mapDisplayEligible) {
      return _primary(
        placement,
        SpatialExposureSurface.companyDetail,
        'Site remains the primary commercial location representation.',
      );
    }
    return _hidden(
      placement,
      SpatialExposureSurface.companyDetail,
      'Non-Site spatial entities are not exposed in commercial UX by CONTRACT 029.',
    );
  }

  SpatialExposureDecision _nearbyRanking(EntityPlacement placement) {
    if (placement.entityType != SpatialEntityType.site ||
        !placement.nearbyRankingEligible) {
      return _hidden(
        placement,
        SpatialExposureSurface.nearbyRanking,
        'Nearby ranking is Site-only and requires explicit eligibility.',
      );
    }
    return _primary(
      placement,
      SpatialExposureSurface.nearbyRanking,
      'Site Placement is explicitly eligible for nearby ranking.',
    );
  }

  SpatialExposureDecision _navigation(EntityPlacement placement) {
    if (placement.entityType != SpatialEntityType.site ||
        !placement.navigationEligible) {
      return _hidden(
        placement,
        SpatialExposureSurface.navigation,
        'Direct navigation is Site-only and requires explicit eligibility.',
      );
    }
    return _primary(
      placement,
      SpatialExposureSurface.navigation,
      'Site Placement is explicitly eligible for direct navigation.',
    );
  }

  SpatialExposureDecision _hidden(
    EntityPlacement placement,
    SpatialExposureSurface surface,
    String reason,
  ) =>
      SpatialExposureDecision(
        placementId: placement.id,
        entityType: placement.entityType,
        entityId: placement.entityId,
        surface: surface,
        mode: SpatialExposureMode.hidden,
        reason: reason,
      );

  SpatialExposureDecision _primary(
    EntityPlacement placement,
    SpatialExposureSurface surface,
    String reason,
  ) =>
      SpatialExposureDecision(
        placementId: placement.id,
        entityType: placement.entityType,
        entityId: placement.entityId,
        surface: surface,
        mode: SpatialExposureMode.primary,
        reason: reason,
      );
}
