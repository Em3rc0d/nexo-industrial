import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:nexo_industrial/features/companies/domain/company.dart';
import 'package:nexo_industrial/features/knowledge/domain/knowledge.dart';
import 'package:nexo_industrial/features/map/ranking_service.dart';
import 'package:nexo_industrial/features/sites/domain/property_facility.dart';
import 'package:nexo_industrial/features/sites/domain/runtime_spatial_projection.dart';
import 'package:nexo_industrial/features/sites/domain/site.dart';
import 'package:nexo_industrial/features/sites/domain/spatial_exposure.dart';

void main() {
  const service = CompanyRankingService();
  const anchor = LatLng(-12.10, -77.03);

  RuntimeCompanySpatialView spatial({
    required String id,
    required String name,
    required double latitude,
    required double longitude,
    required double potential,
    PlacementQuality quality = PlacementQuality.exactAddress,
    bool? nearbyRankingEligible,
    bool? navigationEligible,
  }) {
    final precise =
        quality == PlacementQuality.exactAddress ||
        quality == PlacementQuality.addressReference;
    final nearby = nearbyRankingEligible ?? precise;
    final navigation = navigationEligible ?? precise;

    final company = Company(
      id: id,
      ruc: 'DEMO-$id',
      name: name,
      sector: 'Industrial',
      activity: 'Arenado y pintado',
      opportunityReason: 'Puede consumir recubrimientos.',
      suggestedNextStep: 'Validar compras.',
      address: 'Lima',
      internalPotential: potential,
      auroraProducts: const [],
      sigmaProducts: const [],
      fiscalAddress: null,
      verifiedHqAddress: null,
      commercial: const CommercialProfile(),
      contact: const CompanyContact(),
      source: 'test',
      sourceUpdatedAt: DateTime(2026, 11, 9),
    );

    final placement = EntityPlacement(
      id: 'placement:$id',
      entityType: SpatialEntityType.site,
      entityId: 'site:$id',
      latitude: latitude,
      longitude: longitude,
      quality: quality,
      confidence: KnowledgeConfidence.high,
      mapDisplayEligible: true,
      nearbyRankingEligible: nearby,
      navigationEligible: navigation,
      sourceClaimId: 'claim:$id',
      evidenceIds: const [],
    );

    SpatialExposureDecision decision(
      SpatialExposureSurface surface,
      bool visible,
    ) =>
        SpatialExposureDecision(
          placementId: placement.id,
          entityType: SpatialEntityType.site,
          entityId: placement.entityId,
          surface: surface,
          mode: visible ? SpatialExposureMode.primary : SpatialExposureMode.hidden,
          reason: 'test',
        );

    return RuntimeCompanySpatialView(
      company: company,
      siteId: placement.entityId,
      placement: placement,
      mapExposure: decision(SpatialExposureSurface.commercialMap, true),
      detailExposure: decision(SpatialExposureSurface.companyDetail, true),
      nearbyExposure: decision(SpatialExposureSurface.nearbyRanking, nearby),
      navigationExposure: decision(SpatialExposureSurface.navigation, navigation),
    );
  }

  test('prioriza una oportunidad fuerte y cercana', () {
    final nearStrong = spatial(
      id: '1',
      name: 'Cercana',
      latitude: -12.101,
      longitude: -77.031,
      potential: 0.95,
    );

    final farWeak = spatial(
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

  test('una dirección precisa precede a un centro distrital cercano', () {
    final approximate = spatial(
      id: 'district',
      name: 'District',
      latitude: -12.10,
      longitude: -77.03,
      potential: 1.0,
      quality: PlacementQuality.districtReference,
    );
    final precise = spatial(
      id: 'address',
      name: 'Address',
      latitude: -12.101,
      longitude: -77.031,
      potential: 0.5,
    );
    expect(
      service.rank([approximate, precise], anchor).first.company.id,
      'address',
    );
  });

  test('la auditoría puede negar cercanía incluso a una dirección exacta', () {
    final item = spatial(
      id: 'exact-blocked',
      name: 'Exact blocked',
      latitude: -12.1001,
      longitude: -77.0301,
      potential: 0.75,
      quality: PlacementQuality.exactAddress,
      nearbyRankingEligible: false,
      navigationEligible: false,
    );

    expect(item.canUseDistanceForRanking, isFalse);
  });

  test('una interpolación auditada como no elegible no usa cercanía', () {
    final item = spatial(
      id: 'interpolated-blocked',
      name: 'Interpolated blocked',
      latitude: -12.1001,
      longitude: -77.0301,
      potential: 0.75,
      quality: PlacementQuality.interpolatedAddress,
      nearbyRankingEligible: false,
      navigationEligible: false,
    );

    expect(item.canUseDistanceForRanking, isFalse);
  });

  test('una interpolación promovida explícitamente puede usar cercanía con peso reducido', () {
    final item = spatial(
      id: 'interpolated-approved',
      name: 'Interpolated approved',
      latitude: -12.1001,
      longitude: -77.0301,
      potential: 0.75,
      quality: PlacementQuality.interpolatedAddress,
      nearbyRankingEligible: true,
      navigationEligible: false,
    );

    expect(item.canUseDistanceForRanking, isTrue);
    expect(item.navigationEligible, isFalse);
    expect(item.distanceEvidenceWeight, 0.55);
  });

  test('la búsqueda filtra por nombre', () {
    final metal = spatial(
      id: '1',
      name: 'Metal Demo',
      latitude: -12.101,
      longitude: -77.031,
      potential: 0.8,
    );

    final naval = spatial(
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
