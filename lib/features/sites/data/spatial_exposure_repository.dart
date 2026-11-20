import '../domain/spatial_exposure.dart';
import '../domain/unified_spatial.dart';
import 'spatial_entity_exposure_policy.dart';
import 'unified_spatial_placement_repository.dart';

class SpatialExposureSnapshot {
  SpatialExposureSnapshot({
    required this.spatial,
    required List<SpatialExposureDecision> decisions,
  }) : decisions = List.unmodifiable(decisions);

  final UnifiedSpatialSnapshot spatial;
  final List<SpatialExposureDecision> decisions;

  Iterable<SpatialExposureDecision> forSurface(
    SpatialExposureSurface surface,
  ) =>
      decisions.where((decision) => decision.surface == surface);

  Iterable<SpatialExposureDecision> visibleOn(
    SpatialExposureSurface surface,
  ) =>
      forSurface(surface).where((decision) => decision.isVisible);
}

class SpatialExposureRepository {
  const SpatialExposureRepository({
    this.spatialRepository = const UnifiedSpatialPlacementRepository(),
    this.policy = const SpatialEntityExposurePolicy(),
  });

  final UnifiedSpatialPlacementRepository spatialRepository;
  final SpatialEntityExposurePolicy policy;

  Future<SpatialExposureSnapshot> loadSnapshot() async {
    final spatial = await spatialRepository.loadSnapshot();
    final decisions = <SpatialExposureDecision>[];

    for (final placement in spatial.placements) {
      for (final surface in SpatialExposureSurface.values) {
        decisions.add(policy.decide(placement, surface));
      }
    }

    return SpatialExposureSnapshot(
      spatial: spatial,
      decisions: decisions,
    );
  }
}
