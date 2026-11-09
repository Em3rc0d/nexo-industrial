import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/company.dart';

class AssetCompanyRepository {
  const AssetCompanyRepository({
    this.assetPath = 'assets/data/companies.production.json',
  });

  final String assetPath;

  Future<List<Company>> loadCompanies() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;

    return decoded
        .map((item) => Company.fromJson(item as Map<String, dynamic>))
        .where((company) => company.hasMapCoordinates)
        .toList(growable: false);
  }
}
