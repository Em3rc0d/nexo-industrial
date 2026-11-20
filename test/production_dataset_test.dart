import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexo_industrial/features/map/ranking_service.dart';
import 'package:nexo_industrial/features/companies/data/asset_company_repository.dart';
import 'package:nexo_industrial/features/sites/domain/site.dart';
import 'package:nexo_industrial/features/sites/data/runtime_spatial_projection_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'production contains 1907 unique RUCs with authoritative runtime coverage',
    () async {
      final runtime =
          await const RuntimeSpatialProjectionRepository().loadSnapshot();
      final accounts = runtime.companies;
      final views = runtime.spatialViews;

      expect(accounts, hasLength(1907));
      expect(accounts.map((c) => c.ruc).toSet(), hasLength(1907));
      expect(views, hasLength(1907));
      expect(views.every((view) => view.mapVisible), isTrue);
      expect(
        views.where((view) => view.navigationEligible),
        hasLength(370),
      );
      expect(
        views.where((view) => view.canUseDistanceForRanking),
        hasLength(370),
      );

      final qualities = <PlacementQuality, int>{
        for (final quality in PlacementQuality.values) quality: 0,
      };
      for (final view in views) {
        qualities[view.locationQuality] =
            (qualities[view.locationQuality] ?? 0) + 1;
        expect(view.company.address.trim(), isNotEmpty);
        expect(view.company.commercial.hasOfferData, isTrue);
      }

      expect(qualities[PlacementQuality.exactAddress], 334);
      expect(qualities[PlacementQuality.addressReference], 36);
      expect(qualities[PlacementQuality.interpolatedAddress], 137);
      expect(qualities[PlacementQuality.streetReference], 551);
      expect(qualities[PlacementQuality.districtReference], 849);
    },
  );
  test(
    'Callao and southern accounts remain visible beyond the old top-90 cap',
    () async {
      final runtime = await const RuntimeSpatialProjectionRepository().loadSnapshot();
      final spatial = runtime.spatialViews;
      const service = CompanyRankingService();
      final allBounds = LatLngBounds.fromPoints(
        spatial.map((c) => c.point).toList(),
      );
      expect(service.rankVisible(spatial, allBounds), hasLength(1907));
      final callaoSpatial = spatial
          .where((v) => v.placement.province == 'CALLAO')
          .toList();
      expect(callaoSpatial, hasLength(113));
      final callaoBounds = LatLngBounds.fromPoints(
        callaoSpatial.map((c) => c.point).toList(),
      );
      final visibleRucs = service
          .rankVisible(spatial, callaoBounds)
          .map((x) => x.company.ruc)
          .toSet();
      expect(visibleRucs, containsAll(callaoSpatial.map((v) => v.company.ruc)));
      for (final district in ['LURIN', 'VILLA EL SALVADOR']) {
        final southSpatial = spatial
            .where((v) => v.placement.district == district)
            .toList();
        expect(southSpatial, isNotEmpty);
        final bounds = LatLngBounds.fromPoints(
          southSpatial.map((c) => c.point).toList(),
        );
        final visible = service
            .rankVisible(spatial, bounds)
            .map((x) => x.company.ruc)
            .toSet();
        expect(visible, containsAll(southSpatial.map((v) => v.company.ruc)));
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
