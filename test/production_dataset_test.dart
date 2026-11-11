import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/companies/data/asset_company_repository.dart';
import 'package:nexo_industrial/features/companies/domain/company.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('production contains 1907 unique RUCs with audited map coverage', () async {
    final accounts = await const AssetCompanyRepository().loadCompanies();

    expect(accounts, hasLength(1907));
    expect(accounts.map((c) => c.ruc).toSet(), hasLength(1907));
    expect(accounts.every((c) => c.hasMapCoordinates), isTrue);

    final qualities = <LocationQuality, int>{
      for (final quality in LocationQuality.values) quality: 0,
    };

    for (final company in accounts) {
      qualities[company.locationQuality] =
          (qualities[company.locationQuality] ?? 0) + 1;

      expect(company.address.trim(), isNotEmpty);
      expect(company.commercial.hasOfferData, isTrue);
      final uri = company.navigationEligible
          ? company.googleMapsDirectionsUri
          : company.googleMapsSearchUri;
      expect(uri.scheme, 'https');
      expect(uri.host, 'www.google.com');
      expect(uri.queryParameters['api'], '1');
      if (!company.navigationEligible) {
        expect(uri.queryParameters['query'], contains(company.name));
        expect(uri.queryParameters['query'], contains(company.address));
      }

      if (company.navigationEligible) {
        expect(company.hasReliableCoordinates, isTrue);
        expect(company.nearbyRankingEligible, isTrue);
      }
    }

    expect(qualities[LocationQuality.exactAddress], 334);
    expect(qualities[LocationQuality.addressReference], 36);
    expect(qualities[LocationQuality.interpolatedAddress], 137);
    expect(qualities[LocationQuality.streetReference], 551);
    expect(qualities[LocationQuality.districtReference], 849);

    expect(accounts.where((c) => c.navigationEligible), hasLength(370));
  });
}
