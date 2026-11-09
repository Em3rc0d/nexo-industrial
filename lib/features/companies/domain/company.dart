import 'package:latlong2/latlong.dart';

enum LocationConfidence {
  confirmed,
  fiscalOnly,
  uncertain;

  static LocationConfidence fromJson(String? value) {
    return switch (value) {
      'confirmed' => LocationConfidence.confirmed,
      'fiscal_only' => LocationConfidence.fiscalOnly,
      _ => LocationConfidence.uncertain,
    };
  }
}

class CompanyContact {
  const CompanyContact({
    this.name,
    this.role,
    this.phone,
    this.email,
  });

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
  final String? managementStatus;

  LatLng get point => LatLng(latitude, longitude);

  bool get hasReliableCoordinates =>
      locationConfidence != LocationConfidence.uncertain;

  String get locationLabel => switch (locationConfidence) {
        LocationConfidence.confirmed => 'Central documentada',
        LocationConfidence.fiscalOnly =>
          'Domicilio fiscal · confirmar central',
        LocationConfidence.uncertain => 'Ubicación por confirmar',
      };

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String,
      ruc: json['ruc'] as String,
      name: json['name'] as String,
      sector: json['sector'] as String,
      activity: json['activity'] as String,
      opportunityReason: json['opportunity_reason'] as String,
      suggestedNextStep: json['suggested_next_step'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationConfidence:
          LocationConfidence.fromJson(json['location_confidence'] as String?),
      internalPotential: (json['internal_potential'] as num).toDouble(),
      auroraProducts: List<String>.from(
        json['aurora_products'] as List<dynamic>? ?? const [],
      ),
      sigmaProducts: List<String>.from(
        json['sigma_products'] as List<dynamic>? ?? const [],
      ),
      contact: CompanyContact.fromJson(
        json['contact'] as Map<String, dynamic>?,
      ),
      source: json['source'] as String,
      sourceUpdatedAt: DateTime.parse(json['source_updated_at'] as String),
      managementStatus: json['management_status'] as String?,
    );
  }
}
