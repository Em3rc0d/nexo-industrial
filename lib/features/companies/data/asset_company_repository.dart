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
    this.peopleAssetPath =
        'data/people_enrichment/2026-11-11_mining_people.json',
  });

  final String assetPath;
  final String commercialOverlayPath;
  final String geolocationOverlayPath;
  final String peopleAssetPath;

  Future<List<Company>> loadCompanies() async {
    final raw = await rootBundle.loadString(assetPath);
    final commercialBytes = await rootBundle.load(commercialOverlayPath);
    final overlayRaw = await rootBundle.loadString(geolocationOverlayPath);
    final peopleRaw = await rootBundle.loadString(peopleAssetPath);

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
    final peopleDecoded = jsonDecode(peopleRaw) as Map<String, dynamic>;
    final peopleRecords = peopleDecoded['records'] as List<dynamic>? ?? const [];

    final commercialByRuc = <String, Map<String, dynamic>>{
      for (final item in commercialDecoded)
        (item as Map<String, dynamic>)['ruc'].toString(): item,
    };
    final overlayByRuc = <String, Map<String, dynamic>>{
      for (final item in overlayDecoded)
        (item as Map<String, dynamic>)['ruc'].toString(): item,
    };

    // Public professional identities are an independent overlay: never inflate
    // telephone/email counts and never create new company accounts.
    final peopleByRuc = <String, List<Map<String, dynamic>>>{};
    final profileKeys = <String>{};
    for (final rawPerson in peopleRecords) {
      final person = Map<String, dynamic>.from(rawPerson as Map);
      final ruc = person['ruc'].toString();
      final name = (person['name'] as String?)?.trim() ?? '';
      if (!commercialByRuc.containsKey(ruc) || name.isEmpty) {
        throw FormatException('Unknown RUC or unnamed public professional: $ruc');
      }
      if (!profileKeys.add('$ruc|${name.toLowerCase()}')) {
        throw FormatException('Duplicate professional identity: $ruc / $name');
      }
      (peopleByRuc[ruc] ??= []).add(person);
    }

    final companies = <Company>[];

    for (final rawItem in decoded) {
      final item = Map<String, dynamic>.from(rawItem as Map<String, dynamic>);
      final ruc = item['ruc'].toString();
      final commercial = commercialByRuc[ruc];
      final overlay = overlayByRuc[ruc];
      item['people'] = peopleByRuc[ruc] ?? const <Map<String, dynamic>>[];

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
