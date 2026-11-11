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
    this.contactPatchAssetPath = 'assets/data/companies.contact.patch.json',
  });

  final String assetPath;
  final String commercialOverlayPath;
  final String geolocationOverlayPath;
  final String peopleAssetPath;
  final String contactPatchAssetPath;

  Future<List<Company>> loadCompanies() async {
    final raw = await rootBundle.loadString(assetPath);
    final commercialBytes = await rootBundle.load(commercialOverlayPath);
    final overlayRaw = await rootBundle.loadString(geolocationOverlayPath);
    final peopleRaw = await rootBundle.loadString(peopleAssetPath);
    final contactPatchRaw = await rootBundle.loadString(contactPatchAssetPath);

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
    final contactPatchDecoded = jsonDecode(contactPatchRaw) as Map<String, dynamic>;
    final contactPatchRecords =
        contactPatchDecoded['records'] as List<dynamic>? ?? const [];

    final commercialByRuc = <String, Map<String, dynamic>>{
      for (final item in commercialDecoded)
        (item as Map<String, dynamic>)['ruc'].toString(): item,
    };
    final overlayByRuc = <String, Map<String, dynamic>>{
      for (final item in overlayDecoded)
        (item as Map<String, dynamic>)['ruc'].toString(): item,
    };

    // Only an existing RUC can be enriched: research is NOT prospect discovery.
    // This incremental asset avoids rewriting the audited compressed base file.
    final contactPatchesByRuc = <String, Map<String, dynamic>>{};
    for (final rawPatch in contactPatchRecords) {
      final patch = Map<String, dynamic>.from(rawPatch as Map);
      final ruc = patch['ruc']?.toString() ?? '';
      final source = Uri.tryParse(patch['source_url']?.toString() ?? '');
      if (!commercialByRuc.containsKey(ruc) ||
          patch['status'] != 'published_channel_not_contacted' ||
          source?.scheme != 'https' ||
          source?.host.isNotEmpty != true) {
        throw FormatException('Invalid public contact patch for RUC: $ruc');
      }
      if (contactPatchesByRuc.containsKey(ruc)) {
        throw FormatException('Duplicate public contact patch RUC: $ruc');
      }
      contactPatchesByRuc[ruc] = patch;
    }

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
        final merged = Map<String, dynamic>.from(commercial);
        final patch = contactPatchesByRuc[ruc];
        if (patch != null) {
          final contact = Map<String, dynamic>.from(
            merged['contact'] as Map<String, dynamic>? ?? const {},
          );

          // Never overwrite a previously published direct channel.
          for (final key in ['phone', 'email']) {
            final original = (contact[key] as String?)?.trim() ?? '';
            final candidate = (patch[key] as String?)?.trim() ?? '';
            if (original.isEmpty && candidate.isNotEmpty) {
              contact[key] = candidate;
            }
          }
          // Non-direct metadata may be updated with newer documented evidence.
          for (final key in [
            'website',
            'contact_page',
            'reviewed_on',
            'channel_purpose',
            'source_type',
            'notes',
          ]) {
            final value = patch[key];
            if (value is String && value.trim().isNotEmpty) {
              contact[key] = value;
            }
          }
          final sources = <String>{
            ...((contact['source'] as String?) ?? '')
                .split(' | ')
                .where((value) => value.trim().isNotEmpty),
            patch['source_url'] as String,
            if ((patch['email_source_url'] as String?)?.isNotEmpty == true)
              patch['email_source_url'] as String,
          };
          contact['source'] = sources.join(' | ');
          merged['contact'] = contact;
          merged['contact_source'] = contact['source'];
        }
        item['commercial'] = merged;
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
