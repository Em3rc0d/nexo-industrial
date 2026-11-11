import 'package:latlong2/latlong.dart';

enum LocationQuality {
  exactAddress,
  addressReference,
  interpolatedAddress,
  streetReference,
  districtReference;

  static LocationQuality fromJson(String? value) {
    return switch (value) {
      'exact_address' => LocationQuality.exactAddress,
      'address_reference' => LocationQuality.addressReference,
      'interpolated_address' => LocationQuality.interpolatedAddress,
      'street_reference' => LocationQuality.streetReference,
      'district_reference' => LocationQuality.districtReference,
      'address_geocoded' => LocationQuality.exactAddress,
      _ => LocationQuality.districtReference,
    };
  }
}

enum LocationConfidence {
  high,
  medium,
  low,
  veryLow;

  static LocationConfidence fromJson(String? value) {
    return switch (value) {
      'high' => LocationConfidence.high,
      'confirmed' => LocationConfidence.high,
      'fiscal_only' => LocationConfidence.high,
      'address_geocoded' => LocationConfidence.high,
      'medium' => LocationConfidence.medium,
      'low' => LocationConfidence.low,
      'very_low' => LocationConfidence.veryLow,
      'district_reference' => LocationConfidence.veryLow,
      _ => LocationConfidence.veryLow,
    };
  }
}

class CompanyContact {
  const CompanyContact({
    this.name,
    this.role,
    this.phone,
    this.email,
    this.source,
  });

  final String? name;
  final String? role;
  final String? phone;
  final String? email;
  final String? source;

  bool get hasDirectContact =>
      (name?.isNotEmpty ?? false) ||
      (phone?.isNotEmpty ?? false) ||
      (email?.isNotEmpty ?? false);

  bool get hasAny => hasDirectContact || (role?.isNotEmpty ?? false);

  factory CompanyContact.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CompanyContact();

    return CompanyContact(
      name: json['name'] as String?,
      role: json['role'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      source: json['source'] as String?,
    );
  }
}

class CommercialProfile {
  const CommercialProfile({
    this.pool,
    this.priority,
    this.tier,
    this.secondarySectors,
    this.workersSunat,
    this.visibleCoactiveDebt,
    this.buyerType,
    this.buysForThirdParties,
    this.primaryApplication,
    this.auroraFit,
    this.sigmaFit,
    this.priorityBrand,
    this.auroraRecommendation,
    this.sigmaRecommendation,
    this.commercialFitReason,
    this.purchaseFrequency,
    this.priceSensitivity,
    this.specificationLevel,
    this.volumeReason,
    this.purchaseModel,
    this.targetRole1,
    this.targetRole2,
    this.enrichmentStatus,
    this.openingScript,
    this.companySource,
    this.contactSource,
    this.sourceDate,
    this.prospectingStatus,
    this.origin,
    this.confidence,
    this.observations,
  });

  final String? pool;
  final String? priority;
  final String? tier;
  final String? secondarySectors;
  final int? workersSunat;
  final String? visibleCoactiveDebt;
  final String? buyerType;
  final String? buysForThirdParties;
  final String? primaryApplication;
  final String? auroraFit;
  final String? sigmaFit;
  final String? priorityBrand;
  final String? auroraRecommendation;
  final String? sigmaRecommendation;
  final String? commercialFitReason;
  final String? purchaseFrequency;
  final String? priceSensitivity;
  final String? specificationLevel;
  final String? volumeReason;
  final String? purchaseModel;
  final String? targetRole1;
  final String? targetRole2;
  final String? enrichmentStatus;
  final String? openingScript;
  final String? companySource;
  final String? contactSource;
  final String? sourceDate;
  final String? prospectingStatus;
  final String? origin;
  final String? confidence;
  final String? observations;

  bool get hasOfferData =>
      (primaryApplication?.isNotEmpty ?? false) ||
      (auroraRecommendation?.isNotEmpty ?? false) ||
      (sigmaRecommendation?.isNotEmpty ?? false);

  factory CommercialProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CommercialProfile();

    return CommercialProfile(
      pool: json['pool'] as String?,
      priority: json['priority'] as String?,
      tier: json['tier'] as String?,
      secondarySectors: json['secondary_sectors'] as String?,
      workersSunat: (json['workers_sunat'] as num?)?.toInt(),
      visibleCoactiveDebt: json['visible_coactive_debt'] as String?,
      buyerType: json['buyer_type'] as String?,
      buysForThirdParties: json['buys_for_third_parties'] as String?,
      primaryApplication: json['primary_application'] as String?,
      auroraFit: json['aurora_fit'] as String?,
      sigmaFit: json['sigma_fit'] as String?,
      priorityBrand: json['priority_brand'] as String?,
      auroraRecommendation: json['aurora_recommendation'] as String?,
      sigmaRecommendation: json['sigma_recommendation'] as String?,
      commercialFitReason: json['commercial_fit_reason'] as String?,
      purchaseFrequency: json['purchase_frequency'] as String?,
      priceSensitivity: json['price_sensitivity'] as String?,
      specificationLevel: json['specification_level'] as String?,
      volumeReason: json['volume_reason'] as String?,
      purchaseModel: json['purchase_model'] as String?,
      targetRole1: json['target_role_1'] as String?,
      targetRole2: json['target_role_2'] as String?,
      enrichmentStatus: json['enrichment_status'] as String?,
      openingScript: json['opening_script'] as String?,
      companySource: json['company_source'] as String?,
      contactSource: json['contact_source'] as String?,
      sourceDate: json['source_date'] as String?,
      prospectingStatus: json['prospecting_status'] as String?,
      origin: json['origin'] as String?,
      confidence: json['confidence'] as String?,
      observations: json['observations'] as String?,
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
    required this.fiscalAddress,
    required this.verifiedHqAddress,
    required this.latitude,
    required this.longitude,
    required this.locationQuality,
    required this.locationConfidence,
    required this.internalPotential,
    required this.auroraProducts,
    required this.sigmaProducts,
    required this.contact,
    required this.commercial,
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
  final String? fiscalAddress;
  final String? verifiedHqAddress;
  final double latitude;
  final double longitude;
  final LocationQuality locationQuality;
  final LocationConfidence locationConfidence;

  /// Solo ranking interno. Nunca mostrar el número al vendedor.
  final double internalPotential;

  final List<String> auroraProducts;
  final List<String> sigmaProducts;
  final CompanyContact contact;
  final CommercialProfile commercial;
  final String source;
  final DateTime sourceUpdatedAt;
  final bool nearbyRankingEligible;
  final bool navigationEligible;
  final String? locationDistrict;
  final String? locationProvince;
  final String? locationDepartment;
  final String? managementStatus;

  bool matchesQuery(String query) {
    String normalize(String value) {
      var result = value.trim().toLowerCase();
      const accents = {
        'á': 'a',
        'é': 'e',
        'í': 'i',
        'ó': 'o',
        'ú': 'u',
        'ü': 'u',
      };
      for (final entry in accents.entries) {
        result = result.replaceAll(entry.key, entry.value);
      }
      return result;
    }

    final term = normalize(query);
    if (term.isEmpty) return true;
    return [
      name,
      ruc,
      sector,
      activity,
      address,
      locationDistrict ?? '',
      locationProvince ?? '',
      locationDepartment ?? '',
    ].any((value) => normalize(value).contains(term));
  }

  LatLng get point => LatLng(latitude, longitude);

  bool get hasMapCoordinates =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  bool get hasReliableCoordinates =>
      locationQuality == LocationQuality.exactAddress ||
      locationQuality == LocationQuality.addressReference;

  bool get canUseDistanceForRanking =>
      nearbyRankingEligible ||
      locationQuality == LocationQuality.exactAddress ||
      locationQuality == LocationQuality.addressReference ||
      locationQuality == LocationQuality.interpolatedAddress;

  double get distanceEvidenceWeight => switch (locationQuality) {
    LocationQuality.exactAddress => 1.0,
    LocationQuality.addressReference => 0.95,
    LocationQuality.interpolatedAddress => 0.55,
    LocationQuality.streetReference => 0.0,
    LocationQuality.districtReference => 0.0,
  };

  String get googleMapsSearchQuery {
    final parts = <String>[
      name,
      address,
      ?locationDistrict,
      ?locationProvince,
      ?locationDepartment,
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
    <String, String>{'api': '1', 'destination': '$latitude,$longitude'},
  );

  String get locationActionLabel =>
      navigationEligible ? 'Cómo llegar' : 'Buscar en Maps';

  String get addressTypeLabel => verifiedHqAddress?.isNotEmpty == true
      ? 'HQ verificada'
      : 'Domicilio fiscal';

  String get locationLabel => switch (locationQuality) {
    LocationQuality.exactAddress =>
      'Dirección precisa · confirmar sede operativa',
    LocationQuality.addressReference =>
      'Dirección verificada · confirmar sede operativa',
    LocationQuality.interpolatedAddress =>
      'Dirección aproximada · validar antes de visitar',
    LocationQuality.streetReference =>
      'Referencia de calle · búsqueda en Maps disponible',
    LocationQuality.districtReference =>
      'Referencia distrital · búsqueda en Maps disponible',
  };

  String get compactLocationLabel => switch (locationQuality) {
    LocationQuality.exactAddress => 'Precisa',
    LocationQuality.addressReference => 'Dirección',
    LocationQuality.interpolatedAddress => 'Aprox.',
    LocationQuality.streetReference => 'Calle',
    LocationQuality.districtReference => 'Distrital',
  };

  factory Company.fromJson(Map<String, dynamic> json) {
    final geography = json['geography'] as Map<String, dynamic>?;
    final commercialJson = json['commercial'] as Map<String, dynamic>?;
    final commercial = CommercialProfile.fromJson(commercialJson);
    final isProductionShape = geography != null;

    final latitude = isProductionShape
        ? (geography['latitude'] as num).toDouble()
        : (json['latitude'] as num).toDouble();
    final longitude = isProductionShape
        ? (geography['longitude'] as num).toDouble()
        : (json['longitude'] as num).toDouble();

    final sector = (json['sector'] as String?) ?? 'Industrial';
    final verifiedHqAddress =
        (commercialJson?['address_hq_verified'] as String?) ??
        (json['address_hq_verified'] as String?);
    final fiscalAddress = json['fiscal_address'] as String?;
    final address = isProductionShape
        ? (verifiedHqAddress ??
              fiscalAddress ??
              [
                geography['district'],
                geography['province'],
                geography['department'],
              ].whereType<String>().join(', '))
        : (json['address'] as String);

    final qualityRaw = isProductionShape
        ? (geography['location_quality'] ?? geography['precision']) as String?
        : json['location_quality'] as String?;
    final confidenceRaw = isProductionShape
        ? (geography['location_confidence'] ?? geography['precision'])
              as String?
        : json['location_confidence'] as String?;

    final contactJson =
        (commercialJson?['contact'] as Map<String, dynamic>?) ??
        (json['contact'] as Map<String, dynamic>?);
    final contact = CompanyContact.fromJson({
      ...?contactJson,
      if (commercial.contactSource != null) 'source': commercial.contactSource,
    });

    final opportunityReason =
        commercial.commercialFitReason ??
        (json['opportunity_reason'] as String?) ??
        'Cuenta priorizada para prospección industrial en el sector $sector. '
            'Validar necesidad, volumen, aplicación y proceso de compra antes de cotizar.';

    final target = commercial.targetRole1;
    final suggestedNextStep =
        (json['suggested_next_step'] as String?) ??
        (target != null
            ? 'Contactar o validar a $target y confirmar necesidad, volumen y proceso de compra.'
            : 'Validar la ubicación operativa y contactar a compras, abastecimiento o mantenimiento.');

    return Company(
      id: json['id'].toString(),
      ruc: json['ruc'].toString(),
      name: json['name'] as String,
      sector: sector,
      activity: (json['activity'] as String?) ?? sector,
      opportunityReason: opportunityReason,
      suggestedNextStep: suggestedNextStep,
      address: address,
      fiscalAddress: fiscalAddress,
      verifiedHqAddress: verifiedHqAddress,
      latitude: latitude,
      longitude: longitude,
      locationQuality: LocationQuality.fromJson(qualityRaw),
      locationConfidence: LocationConfidence.fromJson(confidenceRaw),
      internalPotential: json['internal_potential'] != null
          ? (json['internal_potential'] as num).toDouble()
          : ((commercialJson?['score'] ?? json['score']) as num?)?.toDouble() !=
                null
          ? ((commercialJson?['score'] ?? json['score']) as num).toDouble() /
                100
          : 0,
      auroraProducts: List<String>.from(
        json['aurora_products'] as List<dynamic>? ?? const [],
      ),
      sigmaProducts: List<String>.from(
        json['sigma_products'] as List<dynamic>? ?? const [],
      ),
      contact: contact,
      commercial: commercial,
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
                    ? 'Dirección georreferenciada · confirmar sede operativa'
                    : 'Ubicación aproximada · validar antes de visitar')
              : null),
    );
  }
}
