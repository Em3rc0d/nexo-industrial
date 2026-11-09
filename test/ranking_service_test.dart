import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexo_industrial/features/companies/domain/company.dart';
import 'package:nexo_industrial/features/map/ranking_service.dart';

void main() {
  const service = CompanyRankingService();
  const anchor = LatLng(-12.10, -77.03);

  Company company({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    required double potential,
  }) {
    return Company(
      id: id,
      ruc: 'DEMO-$id',
      name: name,
      sector: 'Industrial',
      activity: 'Arenado y pintado',
      opportunityReason: 'Puede consumir recubrimientos.',
      suggestedNextStep: 'Validar compras.',
      address: 'Lima',
      latitude: latitude,
      longitude: longitude,
      locationConfidence: LocationConfidence.confirmed,
      internalPotential: potential,
      auroraProducts: const [],
      sigmaProducts: const [],
      contact: const CompanyContact(),
      source: 'test',
      sourceUpdatedAt: DateTime(2026, 11, 9),
    );
  }

  test('prioriza una oportunidad fuerte y cercana', () {
    final nearStrong = company(
      id: '1',
      name: 'Cercana',
      latitude: -12.101,
      longitude: -77.031,
      potential: 0.95,
    );

    final farWeak = company(
      id: '2',
      name: 'Lejana',
      latitude: -12.18,
      longitude: -77.10,
      potential: 0.45,
    );

    final result = service.rank([farWeak, nearStrong], anchor);

    expect(result.first.company.id, '1');
    expect(result.first.distanceKm, lessThan(result.last.distanceKm));
  });

  test('la búsqueda filtra por nombre', () {
    final metal = company(
      id: '1',
      name: 'Metal Demo',
      latitude: -12.101,
      longitude: -77.031,
      potential: 0.8,
    );

    final naval = company(
      id: '2',
      name: 'Naval Demo',
      latitude: -12.102,
      longitude: -77.032,
      potential: 0.8,
    );

    final result = service.rank([metal, naval], anchor, query: 'naval');

    expect(result, hasLength(1));
    expect(result.single.company.id, '2');
  });
}
