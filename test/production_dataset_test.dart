import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/companies/data/asset_company_repository.dart';
import 'package:nexo_industrial/features/companies/domain/company.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'production contains 1907 unique RUCs and respects geographic precision',
    () async {
      final accounts = await const AssetCompanyRepository().loadCompanies();
      expect(accounts, hasLength(1907));
      expect(accounts.map((c) => c.ruc).toSet(), hasLength(1907));
      for (final company in accounts) {
        expect(company.hasMapCoordinates, isTrue);
        if (company.navigationEligible) {
          expect(company.locationConfidence, LocationConfidence.fiscalOnly);
          expect(company.nearbyRankingEligible, isTrue);
          expect(company.address, contains('NRO'));
        } else {
          expect(company.nearbyRankingEligible, isFalse);
        }
      }
    },
  );
}
