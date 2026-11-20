import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/sites/data/runtime_spatial_projection_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CONTRACT 030 projects all 1907 companies through spatial authority', () async {
    final snapshot =
        await const RuntimeSpatialProjectionRepository().loadSnapshot();

    expect(snapshot.companies, hasLength(1907));
    expect(snapshot.spatialViews, hasLength(1907));
    expect(snapshot.spatialViews.every((v) => v.mapVisible), isTrue);
  });

  test('runtime spatial projection is lossless against legacy geography', () async {
    final snapshot =
        await const RuntimeSpatialProjectionRepository().loadSnapshot();

    for (final view in snapshot.spatialViews) {
      final company = view.company;
      expect(view.point.latitude, company.latitude, reason: company.ruc);
      expect(view.point.longitude, company.longitude, reason: company.ruc);
      expect(view.locationQuality, company.locationQuality, reason: company.ruc);
      expect(
        view.canUseDistanceForRanking,
        company.nearbyRankingEligible,
        reason: company.ruc,
      );
      expect(
        view.navigationEligible,
        company.navigationEligible,
        reason: company.ruc,
      );
    }
  });

  test('runtime eligibility counts preserve production behavior', () async {
    final snapshot =
        await const RuntimeSpatialProjectionRepository().loadSnapshot();

    expect(
      snapshot.spatialViews.where((v) => v.canUseDistanceForRanking),
      hasLength(370),
    );
    expect(
      snapshot.spatialViews.where((v) => v.navigationEligible),
      hasLength(370),
    );
  });

  test('runtime directions use authoritative Placement coordinates', () async {
    final snapshot =
        await const RuntimeSpatialProjectionRepository().loadSnapshot();
    final navigable =
        snapshot.spatialViews.firstWhere((v) => v.navigationEligible);

    expect(
      navigable.googleMapsDirectionsUri.queryParameters['destination'],
      '${navigable.placement.latitude},${navigable.placement.longitude}',
    );
  });

  test('ANA Asset never becomes a runtime Company spatial view', () async {
    final snapshot =
        await const RuntimeSpatialProjectionRepository().loadSnapshot();

    expect(
      snapshot.spatialViews.any(
        (v) =>
            v.placement.entityId ==
            'asset:20501523837:mz-b-lote-1:groundwater-well',
      ),
      isFalse,
    );
  });
}
