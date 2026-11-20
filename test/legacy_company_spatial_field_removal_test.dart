import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/companies/data/asset_company_repository.dart';
import 'package:nexo_industrial/features/sites/data/runtime_spatial_projection_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('commercial Company dataset loads without geolocation overlay dependency', () async {
    final companies = await const AssetCompanyRepository().loadCompanies();
    expect(companies, hasLength(1907));
    expect(companies.map((c) => c.ruc).toSet(), hasLength(1907));
  });

  test('runtime spatial authority preserves complete production behavior', () async {
    final snapshot =
        await const RuntimeSpatialProjectionRepository().loadSnapshot();

    expect(snapshot.companies, hasLength(1907));
    expect(snapshot.spatialViews, hasLength(1907));
    expect(snapshot.spatialViews.every((v) => v.mapVisible), isTrue);
    expect(
      snapshot.spatialViews.where((v) => v.canUseDistanceForRanking),
      hasLength(370),
    );
    expect(
      snapshot.spatialViews.where((v) => v.navigationEligible),
      hasLength(370),
    );
  });

  test('regional search remains spatial-authority driven after Company removal', () async {
    final snapshot =
        await const RuntimeSpatialProjectionRepository().loadSnapshot();

    expect(
      snapshot.spatialViews.where((v) => v.matchesQuery('Callao')).length,
      greaterThanOrEqualTo(113),
    );
    expect(
      snapshot.spatialViews.where((v) => v.matchesQuery('Lurín')).length,
      greaterThanOrEqualTo(46),
    );
    expect(
      snapshot.spatialViews
          .where((v) => v.matchesQuery('Villa El Salvador'))
          .length,
      greaterThanOrEqualTo(30),
    );
  });
}
