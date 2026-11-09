import 'package:latlong2/latlong.dart';

enum LocationConfidence {
  confirmed,
  fiscalOnly,
  districtReference,
  uncertain;

  static LocationConfidence fromJson(String? value) {
    return switch (value) {
      'confirmed' => LocationConfidence.confirmed,
      'fiscal_only' => LocationConfidence.fiscalOnly,
      'address_geocoded' => LocationConfidence.fiscalOnly,
      'district_reference' => LocationConfidence.districtReference,
      _ => LocationConfidence.uncertain,
    };
  }
}

class CompanyContact {
  const CompanyContact({this.name, this.role, this.phone, this.email});

  final String? name;
  final String? role;
  final String? phone;
  final String? email;

  bool get hasAny =>
      (name?.isNotEmpty ?? false) ||
      (role?.isNotEmpty ?? false) ||
      (phone?.isNotEmpty ?? false) ||
      (email?.isNotEmpty ?? false);

  factory CompanyContact.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CompanyContact();

    return CompanyContact(
      name: json['name'] as String?,
      role: json['role'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }
}

class Company {
  const Company({
    required this.id,
    required this.ruc,
    required this.name,
    required this.sector,
    required this.activity,
    required this.opportunityReason,
    required this.suggestedNextStep,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.locationConfidence,
    required this.internalPotential,
    required this.auroraProducts,
    required this.sigmaProducts,
    required this.contact,
    required this.source,
    required this.sourceUpdatedAt,
    required this.nearbyRankingEligible,
    required this.navigationEligible,
    this.locationDistrict,
    this.locationProvince,
    this.locationDepartment,
    this.managementStatus,
  });

  final String id;
  final String ruc;
  final String name;
  final String sector;
  final String activity;
  final String opportunityReason;
  final String suggestedNextStep;
  final String address;
  final double latitude;
  final double longitude;
  final LocationConfidence locationConfidence;

  /// Solo ranking interno. Nunca mostrar el número al vendedor.
  final double internalPotential;

  final List<String> auroraProducts;
  final List<String> sigmaProducts;
  final CompanyContact contact;
  final String source;
  final DateTime sourceUpdatedAt;
  final bool nearbyRankingEligible;
  final bool navigationEligible;
  final String? locationDistrict;
  final String? locationProvince;
  final String? locationDepartment;
  final String? managementStatus;

  LatLng get point => LatLng(latitude, longitude);

  bool get hasMapCoordinates =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  bool get hasReliableCoordinates =>
      locationConfidence == LocationConfidence.confirmed ||
      locationConfidence == LocationConfidence.fiscalOnly;

  String get googleMapsSearchQuery {
    final parts = <String>[
      name,
      address,
      if (locationDistrict case final district?) district,
      if (locationProvince case final province?) province,
      if (locationDepartment case final department?) department,
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
      'destination': '$latitude,$longitude',
    },
  );

  String get locationActionLabel =>
      navigationEligible ? 'Cómo llegar' : 'Buscar en Maps';

  String get locationLabel => switch (locationConfidence) {
    LocationConfidence.confirmed => 'Central documentada',
    LocationConfidence.fiscalOnly => 'Domicilio fiscal · confirmar central',
    LocationConfidence.districtReference =>
      'Referencia distrital · búsqueda en Maps disponible',
    LocationConfidence.uncertain =>
      'Ubicación aproximada · búsqueda en Maps disponible',
  };

  factory Company.fromJson(Map<String, dynamic> json) {
    final geography = json['geography'] as Map<String, dynamic>?;
    final isProductionShape = geography != null;

    final latitude = isProductionShape
        ? (geography['latitude'] as num).toDouble()
        : (json['latitude'] as num).toDouble();
    final longitude = isProductionShape
        ? (geography['longitude'] as num).toDouble()
        : (json['longitude'] as num).toDouble();

    final sector = (json['sector'] as String?) ?? 'Industrial';
    final address = isProductionShape
        ? ((json['fiscal_address'] as String?) ??
              (json['address_hq_verified'] as String?) ??
              [
                geography['district'],
                geography['province'],
                geography['department'],
              ].whereType<String>().join(', '))
        : (json['address'] as String);

    return Company(
      id: json['id'].toString(),
      ruc: json['ruc'].toString(),
      name: json['name'] as String,
      sector: sector,
      activity: (json['activity'] as String?) ?? sector,
      opportunityReason:
          (json['opportunity_reason'] as String?) ??
          'Cuenta priorizada para prospección industrial en el sector $sector. '
              'Validar necesidad, volumen, aplicación y proceso de compra antes de cotizar.',
      suggestedNextStep:
          (json['suggested_next_step'] as String?) ??
          'Validar la ubicación operativa y contactar a compras, abastecimiento o mantenimiento.',
      address: address,
      latitude: latitude,
      longitude: longitude,
      locationConfidence: LocationConfidence.fromJson(
        isProductionShape
            ? geography['precision'] as String?
            : json['location_confidence'] as String?,
      ),
      internalPotential: json['internal_potential'] != null
          ? (json['internal_potential'] as num).toDouble()
          : ((json['score'] as num?)?.toDouble() ?? 0) / 100,
      auroraProducts: List<String>.from(
        json['aurora_products'] as List<dynamic>? ?? const [],
      ),
      sigmaProducts: List<String>.from(
        json['sigma_products'] as List<dynamic>? ?? const [],
      ),
      contact: CompanyContact.fromJson(
        json['contact'] as Map<String, dynamic>?,
      ),
      source: isProductionShape
          ? (geography['source'] as String? ?? 'Dataset maestro Nexo')
          : (json['source'] as String),
      sourceUpdatedAt: json['source_updated_at'] != null
          ? DateTime.parse(json['source_updated_at'] as String)
          : DateTime.tryParse(
                  (geography?['geocoded_at'] ??
                              geography?['geocoding_checked_at'] ??
                              json['fiscal_address_as_of'])
                          as String? ??
                      '',
                ) ??
                DateTime(2026, 11, 9),
      nearbyRankingEligible: isProductionShape
          ? (geography['nearby_ranking_eligible'] as bool? ?? false)
          : true,
      navigationEligible: isProductionShape
          ? (geography['navigation_eligible'] as bool? ?? false)
          : true,
      locationDistrict: isProductionShape
          ? geography['district'] as String?
          : null,
      locationProvince: isProductionShape
          ? geography['province'] as String?
          : null,
      locationDepartment: isProductionShape
          ? geography['department'] as String?
          : null,
      managementStatus:
          (json['management_status'] as String?) ??
          (isProductionShape
              ? (geography['navigation_eligible'] == true
                    ? 'Domicilio fiscal geocodificado · confirmar central'
                    : 'Referencia distrital · búsqueda en Maps disponible')
              : null),
    );
  }
}
