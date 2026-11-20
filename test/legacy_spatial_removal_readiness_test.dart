import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/companies/domain/company.dart';
import 'package:nexo_industrial/features/sites/data/runtime_spatial_projection_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Company can be constructed without legacy spatial fields', () {
    final company = Company(
      id: 'demo',
      ruc: '20000000000',
      name: 'Demo',
      sector: 'Industrial',
      activity: 'Industrial',
      opportunityReason: 'Demo',
      suggestedNextStep: 'Demo',
      address: 'Lima',
      fiscalAddress: null,
      verifiedHqAddress: null,
      internalPotential: 0.5,
      auroraProducts: [],
      sigmaProducts: [],
      contact: CompanyContact(),
      commercial: CommercialProfile(),
      source: 'test',
      sourceUpdatedAt: DateTime(2026, 11, 20),
    );

    expect(company.name, 'Demo');
  });

  test('runtime coverage remains complete without Company spatial authority', () async {
    final snapshot =
        await const RuntimeSpatialProjectionRepository().loadSnapshot();

    expect(snapshot.companies, hasLength(1907));
    expect(snapshot.spatialViews, hasLength(1907));
    expect(
      snapshot.spatialViews.where((v) => v.canUseDistanceForRanking),
      hasLength(370),
    );
    expect(
      snapshot.spatialViews.where((v) => v.navigationEligible),
      hasLength(370),
    );
  });
}
