import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/sites/data/spatial_exposure_repository.dart';
import 'package:nexo_industrial/features/sites/domain/property_facility.dart';
import 'package:nexo_industrial/features/sites/domain/spatial_exposure.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SpatialExposureSnapshot snapshot;

  setUpAll(() async {
    snapshot = await const SpatialExposureRepository().loadSnapshot();
  });

  test('CONTRACT 029 exposes exactly 1907 primary Site markers', () {
    final map = snapshot.visibleOn(SpatialExposureSurface.commercialMap).toList();

    expect(map, hasLength(1907));
    expect(map.every((d) => d.entityType == SpatialEntityType.site), isTrue);
    expect(map.every((d) => d.mode == SpatialExposureMode.primary), isTrue);
  });

  test('non-Site entities are fail-closed on commercial surfaces', () {
    final nonSite = snapshot.spatial.placements
        .where((p) => p.entityType != SpatialEntityType.site)
        .toList();

    expect(nonSite, hasLength(1));

    for (final placement in nonSite) {
      for (final surface in SpatialExposureSurface.values) {
        final decision = snapshot.decisions.singleWhere(
          (d) =>
              d.placementId == placement.id &&
              d.surface == surface,
        );
        expect(decision.mode, SpatialExposureMode.hidden);
      }
    }
  });

  test('nearby ranking exposure preserves 370 eligible Sites', () {
    final visible =
        snapshot.visibleOn(SpatialExposureSurface.nearbyRanking).toList();

    expect(visible, hasLength(370));
    expect(visible.every((d) => d.entityType == SpatialEntityType.site), isTrue);
  });

  test('navigation exposure preserves 370 eligible Sites', () {
    final visible =
        snapshot.visibleOn(SpatialExposureSurface.navigation).toList();

    expect(visible, hasLength(370));
    expect(visible.every((d) => d.entityType == SpatialEntityType.site), isTrue);
  });

  test('ANA well is hidden from map, detail, ranking and navigation', () {
    const asset = 'asset:20501523837:mz-b-lote-1:groundwater-well';

    final decisions =
        snapshot.decisions.where((d) => d.entityId == asset).toList();

    expect(decisions, hasLength(4));
    expect(decisions.every((d) => d.mode == SpatialExposureMode.hidden), isTrue);
  });

  test('policy never upgrades raw Placement permissions', () {
    for (final placement in snapshot.spatial.placements) {
      final map = snapshot.decisions.singleWhere(
        (d) =>
            d.placementId == placement.id &&
            d.surface == SpatialExposureSurface.commercialMap,
      );
      final nearby = snapshot.decisions.singleWhere(
        (d) =>
            d.placementId == placement.id &&
            d.surface == SpatialExposureSurface.nearbyRanking,
      );
      final navigation = snapshot.decisions.singleWhere(
        (d) =>
            d.placementId == placement.id &&
            d.surface == SpatialExposureSurface.navigation,
      );

      if (!placement.mapDisplayEligible) expect(map.isVisible, isFalse);
      if (!placement.nearbyRankingEligible) expect(nearby.isVisible, isFalse);
      if (!placement.navigationEligible) expect(navigation.isVisible, isFalse);
    }
  });
}
