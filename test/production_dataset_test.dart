import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexo_industrial/features/map/ranking_service.dart';
import 'package:nexo_industrial/features/companies/data/asset_company_repository.dart';
import 'package:nexo_industrial/features/companies/domain/company.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'production contains 1907 unique RUCs with audited map coverage',
    () async {
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
    },
  );
  test(
    'Callao and southern accounts remain visible beyond the old top-90 cap',
    () async {
      final accounts = await const AssetCompanyRepository().loadCompanies();
      const service = CompanyRankingService();
      final allBounds = LatLngBounds.fromPoints(
        accounts.map((c) => c.point).toList(),
      );
      expect(service.rankVisible(accounts, allBounds), hasLength(1907));
      final callao = accounts
          .where((c) => c.locationProvince == 'CALLAO')
          .toList();
      expect(callao, hasLength(113));
      final callaoBounds = LatLngBounds.fromPoints(
        callao.map((c) => c.point).toList(),
      );
      final visibleRucs = service
          .rankVisible(accounts, callaoBounds)
          .map((x) => x.company.ruc)
          .toSet();
      expect(visibleRucs, containsAll(callao.map((c) => c.ruc)));
      for (final district in ['LURIN', 'VILLA EL SALVADOR']) {
        final south = accounts
            .where((c) => c.locationDistrict == district)
            .toList();
        expect(south, isNotEmpty);
        final bounds = LatLngBounds.fromPoints(
          south.map((c) => c.point).toList(),
        );
        final visible = service
            .rankVisible(accounts, bounds)
            .map((x) => x.company.ruc)
            .toSet();
        expect(visible, containsAll(south.map((c) => c.ruc)));
      }
    },
  );

  test(
    'district search is global, includes approximate locations and handles accents',
    () async {
      final accounts = await const AssetCompanyRepository().loadCompanies();
      const service = CompanyRankingService();
      const anchor = LatLng(-12.1, -77.03);
      final callao = service.rank(accounts, anchor, query: 'Callao');
      expect(callao.length, greaterThanOrEqualTo(113));
      final lurin = service.rank(accounts, anchor, query: 'Lurín');
      expect(lurin.length, greaterThanOrEqualTo(46));
      expect(lurin.any((x) => !x.company.navigationEligible), isTrue);
      expect(
        service.rank(accounts, anchor, query: 'Villa El Salvador').length,
        greaterThanOrEqualTo(30),
      );
    },
  );
}
