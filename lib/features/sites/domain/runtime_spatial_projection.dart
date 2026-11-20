import 'package:latlong2/latlong.dart';

import '../../companies/domain/company.dart';
import 'property_facility.dart';
import 'spatial_exposure.dart';

class RuntimeCompanySpatialView {
  const RuntimeCompanySpatialView({
    required this.company,
    required this.siteId,
    required this.placement,
    required this.mapExposure,
    required this.detailExposure,
    required this.nearbyExposure,
    required this.navigationExposure,
  });

  final Company company;
  final String siteId;
  final EntityPlacement placement;
  final SpatialExposureDecision mapExposure;
  final SpatialExposureDecision detailExposure;
  final SpatialExposureDecision nearbyExposure;
  final SpatialExposureDecision navigationExposure;

  LatLng get point => LatLng(placement.latitude, placement.longitude);
  bool get mapVisible => mapExposure.isVisible;
  bool get canUseDistanceForRanking => nearbyExposure.isVisible;
  bool get navigationEligible => navigationExposure.isVisible;

  LocationQuality get locationQuality => switch (placement.quality) {
        PlacementQuality.exactAddress => LocationQuality.exactAddress,
        PlacementQuality.addressReference => LocationQuality.addressReference,
        PlacementQuality.propertyReference => LocationQuality.districtReference,
        PlacementQuality.interpolatedAddress => LocationQuality.interpolatedAddress,
        PlacementQuality.streetReference => LocationQuality.streetReference,
        PlacementQuality.districtReference => LocationQuality.districtReference,
      };

  double get distanceEvidenceWeight => switch (placement.quality) {
        PlacementQuality.exactAddress => 1.0,
        PlacementQuality.addressReference => 0.95,
        PlacementQuality.interpolatedAddress => 0.55,
        PlacementQuality.propertyReference ||
        PlacementQuality.streetReference ||
        PlacementQuality.districtReference =>
          0.0,
      };

  String get compactLocationLabel => switch (placement.quality) {
        PlacementQuality.exactAddress => 'Precisa',
        PlacementQuality.addressReference => 'Dirección',
        PlacementQuality.interpolatedAddress => 'Aprox.',
        PlacementQuality.propertyReference => 'Propiedad',
        PlacementQuality.streetReference => 'Calle',
        PlacementQuality.districtReference => 'Distrital',
      };

  String get locationLabel => switch (placement.quality) {
        PlacementQuality.exactAddress =>
          'Dirección precisa · confirmar sede operativa',
        PlacementQuality.addressReference =>
          'Dirección verificada · confirmar sede operativa',
        PlacementQuality.interpolatedAddress =>
          'Dirección aproximada · validar antes de visitar',
        PlacementQuality.propertyReference =>
          'Referencia de propiedad · no usar como destino directo',
        PlacementQuality.streetReference =>
          'Referencia de calle · búsqueda en Maps disponible',
        PlacementQuality.districtReference =>
          'Referencia distrital · búsqueda en Maps disponible',
      };

  String get googleMapsSearchQuery {
    final parts = <String>[
      company.name,
      placement.address ?? company.address,
      ?placement.district,
      ?placement.province,
      ?placement.department,
      'Perú',
    ];

    final unique = <String>[];
    final seen = <String>{};
    for (final part in parts) {
      final value = part.trim();
      if (value.isEmpty) continue;
      final key = value.toUpperCase();
      if (seen.add(key)) unique.add(value);
    }
    return unique.join(', ');
  }

  Uri get googleMapsSearchUri => Uri.https(
        'www.google.com',
        '/maps/search/',
        <String, String>{'api': '1', 'query': googleMapsSearchQuery},
      );

  Uri get googleMapsDirectionsUri => Uri.https(
        'www.google.com',
        '/maps/dir/',
        <String, String>{
          'api': '1',
          'destination': '${placement.latitude},${placement.longitude}',
        },
      );

  String get locationActionLabel =>
      navigationEligible ? 'Cómo llegar' : 'Buscar en Maps';
}

class RuntimeSpatialProjectionSnapshot {
  RuntimeSpatialProjectionSnapshot({
    required List<Company> companies,
    required List<RuntimeCompanySpatialView> spatialViews,
  })  : companies = List.unmodifiable(companies),
        spatialViews = List.unmodifiable(spatialViews),
        _byCompanyId = {
          for (final view in spatialViews) view.company.id: view,
        };

  final List<Company> companies;
  final List<RuntimeCompanySpatialView> spatialViews;
  final Map<String, RuntimeCompanySpatialView> _byCompanyId;

  RuntimeCompanySpatialView? forCompanyId(String companyId) =>
      _byCompanyId[companyId];
}
