import 'property_facility.dart';

enum SpatialExposureSurface {
  commercialMap,
  companyDetail,
  nearbyRanking,
  navigation,
}

enum SpatialExposureMode {
  hidden,
  contextual,
  primary,
}

class SpatialExposureDecision {
  const SpatialExposureDecision({
    required this.placementId,
    required this.entityType,
    required this.entityId,
    required this.surface,
    required this.mode,
    required this.reason,
  });

  final String placementId;
  final SpatialEntityType entityType;
  final String entityId;
  final SpatialExposureSurface surface;
  final SpatialExposureMode mode;
  final String reason;

  bool get isVisible => mode != SpatialExposureMode.hidden;
  bool get isPrimary => mode == SpatialExposureMode.primary;
}
