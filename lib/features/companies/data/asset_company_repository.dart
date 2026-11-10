import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../domain/company.dart';

class AssetCompanyRepository {
  const AssetCompanyRepository({
    this.assetPath = 'assets/data/companies.production.json',
    this.commercialOverlayPath =
        'assets/data/companies.commercial.overlay.json.gz',
    this.geolocationOverlayPath =
        'assets/data/companies.geolocation.overlay.json',
  });

  final String assetPath;
  final String commercialOverlayPath;
  final String geolocationOverlayPath;

  Future<List<Company>> loadCompanies() async {
    final raw = await rootBundle.loadString(assetPath);
    final commercialBytes = await rootBundle.load(commercialOverlayPath);
    final overlayRaw = await rootBundle.loadString(geolocationOverlayPath);

    final decoded = jsonDecode(raw) as List<dynamic>;
    final commercialRaw = utf8.decode(
      gzip.decode(
        commercialBytes.buffer.asUint8List(
          commercialBytes.offsetInBytes,
          commercialBytes.lengthInBytes,
        ),
      ),
    );
    final commercialDecoded = jsonDecode(commercialRaw) as List<dynamic>;
    final overlayDecoded = jsonDecode(overlayRaw) as List<dynamic>;

    final commercialByRuc = <String, Map<String, dynamic>>{
      for (final item in commercialDecoded)
        (item as Map<String, dynamic>)['ruc'].toString(): item,
    };
    final overlayByRuc = <String, Map<String, dynamic>>{
      for (final item in overlayDecoded)
        (item as Map<String, dynamic>)['ruc'].toString(): item,
    };

    final companies = <Company>[];

    for (final rawItem in decoded) {
      final item = Map<String, dynamic>.from(rawItem as Map<String, dynamic>);
      final ruc = item['ruc'].toString();
      final commercial = commercialByRuc[ruc];
      final overlay = overlayByRuc[ruc];

      if (commercial != null) {
        item['commercial'] = commercial;
      }

      if (overlay != null) {
        final geography = Map<String, dynamic>.from(
          item['geography'] as Map<String, dynamic>? ?? const {},
        );

        geography.addAll(overlay);
        item['geography'] = geography;
      }

      final company = Company.fromJson(item);
      if (company.hasMapCoordinates) companies.add(company);
    }

    return List.unmodifiable(companies);
  }
}
