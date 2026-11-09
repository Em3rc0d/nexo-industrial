import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/companies/domain/company.dart';

void main() {
  Company company({required bool navigationEligible}) {
    final quality = navigationEligible
        ? LocationQuality.exactAddress
        : LocationQuality.districtReference;

    return Company(
      id: '1',
      ruc: '20610105620',
      name: 'STRACON PERÚ S.A.',
      sector: 'Minería',
      activity: 'Operadores mineros metálicos',
      opportunityReason: 'Prospección industrial.',
      suggestedNextStep: 'Validar compras.',
      address: 'AV. SANTO TORIBIO NRO 143 INT 4',
      latitude: -12.0977777777778,
      longitude: -77.0272222222222,
      locationQuality: quality,
      locationConfidence: navigationEligible
          ? LocationConfidence.high
          : LocationConfidence.veryLow,
      internalPotential: 1,
      auroraProducts: const [],
      sigmaProducts: const [],
      contact: const CompanyContact(),
      source: 'test',
      sourceUpdatedAt: DateTime(2026, 11, 9),
      nearbyRankingEligible: navigationEligible,
      navigationEligible: navigationEligible,
      locationDistrict: 'SAN ISIDRO',
      locationProvince: 'LIMA',
      locationDepartment: 'LIMA',
    );
  }

  test('fallback de ubicación busca empresa y domicilio fiscal en Google Maps', () {
    final item = company(navigationEligible: false);
    final uri = item.googleMapsSearchUri;

    expect(uri.scheme, 'https');
    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/search/');
    expect(uri.queryParameters['api'], '1');
    expect(
      uri.queryParameters['query'],
      'STRACON PERÚ S.A., AV. SANTO TORIBIO NRO 143 INT 4, SAN ISIDRO, LIMA, Perú',
    );
    expect(item.locationActionLabel, 'Buscar en Maps');
  });

  test('ubicación precisa mantiene navegación por coordenadas', () {
    final item = company(navigationEligible: true);
    final uri = item.googleMapsDirectionsUri;

    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['api'], '1');
    expect(
      uri.queryParameters['destination'],
      '-12.0977777777778,-77.0272222222222',
    );
    expect(item.locationActionLabel, 'Cómo llegar');
  });
}
