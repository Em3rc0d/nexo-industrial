import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexo_industrial/features/map/ranking_service.dart';
import 'package:nexo_industrial/features/companies/data/asset_company_repository.dart';
import 'package:nexo_industrial/features/companies/domain/company.dart';
import 'package:nexo_industrial/features/sites/data/runtime_spatial_projection_repository.dart';

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
      expect(accounts.where((c) => c.nearbyRankingEligible), hasLength(370));

      final interpolated = accounts
          .where((c) => c.locationQuality == LocationQuality.interpolatedAddress)
          .toList();
      expect(interpolated, hasLength(137));
      expect(
        interpolated.every((c) =>
            !c.nearbyRankingEligible &&
            !c.navigationEligible &&
            !c.canUseDistanceForRanking),
        isTrue,
      );
    },
  );
  test(
    'Callao and southern accounts remain visible beyond the old top-90 cap',
    () async {
      final runtime = await const RuntimeSpatialProjectionRepository().loadSnapshot();
      final accounts = runtime.companies;
      final spatial = runtime.spatialViews;
      const service = CompanyRankingService();
      final allBounds = LatLngBounds.fromPoints(
        spatial.map((c) => c.point).toList(),
      );
      expect(service.rankVisible(spatial, allBounds), hasLength(1907));
      final callao = accounts
          .where((c) => c.locationProvince == 'CALLAO')
          .toList();
      expect(callao, hasLength(113));
      final callaoIds = callao.map((c) => c.id).toSet();
      final callaoSpatial = spatial.where((v) => callaoIds.contains(v.company.id)).toList();
      final callaoBounds = LatLngBounds.fromPoints(
        callaoSpatial.map((c) => c.point).toList(),
      );
      final visibleRucs = service
          .rankVisible(spatial, callaoBounds)
          .map((x) => x.company.ruc)
          .toSet();
      expect(visibleRucs, containsAll(callao.map((c) => c.ruc)));
      for (final district in ['LURIN', 'VILLA EL SALVADOR']) {
        final south = accounts
            .where((c) => c.locationDistrict == district)
            .toList();
        expect(south, isNotEmpty);
        final southIds = south.map((c) => c.id).toSet();
        final southSpatial = spatial.where((v) => southIds.contains(v.company.id)).toList();
        final bounds = LatLngBounds.fromPoints(
          southSpatial.map((c) => c.point).toList(),
        );
        final visible = service
            .rankVisible(spatial, bounds)
            .map((x) => x.company.ruc)
            .toSet();
        expect(visible, containsAll(south.map((c) => c.ruc)));
      }
    },
  );

  test(
    'district search is global, includes approximate locations and handles accents',
    () async {
      final runtime = await const RuntimeSpatialProjectionRepository().loadSnapshot();
      final spatial = runtime.spatialViews;
      const service = CompanyRankingService();
      const anchor = LatLng(-12.1, -77.03);
      final callao = service.rank(spatial, anchor, query: 'Callao');
      expect(callao.length, greaterThanOrEqualTo(113));
      final lurin = service.rank(spatial, anchor, query: 'Lurín');
      expect(lurin.length, greaterThanOrEqualTo(46));
      expect(lurin.any((x) => !x.spatial.navigationEligible), isTrue);
      expect(
        service.rank(spatial, anchor, query: 'Villa El Salvador').length,
        greaterThanOrEqualTo(30),
      );
    },
  );
  test(
    'recovered registry covers all RUCs without inflating direct channels',
    () async {
      final accounts = await const AssetCompanyRepository().loadCompanies();
      expect(
        accounts.where((c) => c.contact.registryName?.isNotEmpty == true),
        hasLength(1907),
      );
      expect(
        accounts.where((c) => c.contact.phone?.isNotEmpty == true),
        hasLength(292),
      );
      expect(
        accounts.where((c) => c.contact.emailUris.isNotEmpty),
        hasLength(176),
      );
      expect(accounts.where((c) => c.contact.hasDirectContact), hasLength(299));
      final stracon = accounts.singleWhere((c) => c.ruc == '20610105620');
      expect(stracon.contact.registryName, 'Tamayo Ortega John Edwin');
      expect(stracon.contact.registrySource, contains('180813c'));
      expect(
        accounts.singleWhere((c) => c.ruc == '20563693763').contact.email,
        'comercial@arcamgranallados.com.pe',
      );
    },
  );
  test(
    'new Callao/south channels keep web-only and supplier purposes explicit',
    () async {
      final accounts = await const AssetCompanyRepository().loadCompanies();
      final iolsa = accounts.singleWhere((c) => c.ruc == '20547035381');
      expect(iolsa.contact.hasDirectContact, isFalse);
      expect(iolsa.contact.contactPageUri?.host, 'iolsa.pe');
      final ramperu = accounts.singleWhere((c) => c.ruc == '20525376738');
      expect(ramperu.contact.channelPurpose, 'supplier_presentations');
      expect(ramperu.contact.emailUris.single.path, 'cnoriega@ramperu.pe');
      final zeta = accounts.singleWhere((c) => c.ruc == '20262254268');
      expect(zeta.contact.phone, '+51 1 614 0707');
      expect(zeta.contact.email, isNull);
      expect(
        accounts.where((c) => c.contact.contactPageUri != null).length,
        greaterThanOrEqualTo(15),
      );
    },
  );
  test(
    'accepted public contact patch is applied by RUC without new accounts',
    () async {
      final accounts = await const AssetCompanyRepository().loadCompanies();
      expect(accounts, hasLength(1907));
      final casa = accounts.singleWhere((c) => c.ruc == '20109565017');
      expect(casa.contact.phone, '+51 1 611 3939');
      expect(casa.contact.emailUris.single.path, 'casa@casacontratistas.com');

      final jrc = accounts.singleWhere((c) => c.ruc == '20508891149');
      expect(jrc.contact.emailUris.map((x) => x.path),
          contains('compras@jrcing.com.pe'));

      final tecnomin = accounts.singleWhere((c) => c.ruc == '20221259581');
      expect(tecnomin.contact.phone, '+51 1 659 8377');
      expect(tecnomin.contact.emailUris.single.path,
          'administracion@tecnomindata.com');

      final explo = accounts.singleWhere((c) => c.ruc == '20527775851');
      expect(explo.contact.emailUris.map((x) => x.path),
          contains('comercial@explodrillingperu.pe'));

      final paita = accounts.singleWhere((c) => c.ruc == '20522473571');
      expect(paita.contact.channelPurposeLabel,
          contains('Atención al cliente'));

      final quenuales = accounts.singleWhere((c) => c.ruc == '20332907990');
      expect(quenuales.contact.hasDirectContact, isFalse);
      expect(quenuales.contact.contactPageUri?.host, 'alpayana.com');

      final cmh = accounts.singleWhere((c) => c.ruc == '20136150473');
      expect(cmh.contact.phone, '(01) 618-1000');
      expect(cmh.contact.emailUris.single.path, 'contacto@cmh.com.pe');

      final akd = accounts.singleWhere((c) => c.ruc == '20470234599');
      expect(akd.contact.phone, '+51 1 251 3380');
      expect(akd.contact.emailUris.single.path, 'global@akdint.com');

      final evs = accounts.singleWhere((c) => c.ruc == '20539424743');
      expect(evs.contact.phone, '+51 1 704 8970');
      expect(evs.contact.emailUris.single.path,
          'elmer.sotasor@evs.com.pe');
      final sad = accounts.singleWhere((c) => c.ruc == '20536925245');
      expect(sad.contact.phone, isNull);
      expect(sad.contact.emailUris.single.path, 'consultas@sadrilling.com');

      final withAny = accounts.where((c) =>
          c.contact.hasDirectContact || c.contact.contactPageUri != null);
      expect(withAny, hasLength(304));
    },
  );

}
