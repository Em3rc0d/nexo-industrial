import 'property_facility.dart';

class UnifiedSpatialSnapshot {
  UnifiedSpatialSnapshot({
    required List<EntityPlacement> placements,
    required this.legacySitePlacementCount,
    required this.nonSitePlacementCount,
  }) : placements = List.unmodifiable(placements);

  final List<EntityPlacement> placements;
  final int legacySitePlacementCount;
  final int nonSitePlacementCount;

  Iterable<EntityPlacement> placementsForEntity(
    SpatialEntityType type,
    String entityId,
  ) =>
      placements.where(
        (placement) =>
            placement.entityType == type && placement.entityId == entityId,
      );

  Iterable<EntityPlacement> get sitePlacements =>
      placements.where((placement) => placement.entityType == SpatialEntityType.site);

  Iterable<EntityPlacement> get actionablePlacements => placements.where(
        (placement) =>
            placement.nearbyRankingEligible || placement.navigationEligible,
      );
}
