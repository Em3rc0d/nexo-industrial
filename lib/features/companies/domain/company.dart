/// Professional identity from public sources. Never counted as a direct phone/email.
/// Public professional references by RUC; not equivalent to a company phone/email.
class ProfessionalContact {
  const ProfessionalContact({
    required this.name,
    required this.role,
    required this.status,
    required this.reviewedOn,
    this.department,
    this.linkedinUrl,
    this.evidenceUrl,
    this.confidence,
    this.associationScope,
    this.workEmail,
  });

  final String name;
  final String role;
  final String status;
  final String reviewedOn;
  final String? department;
  final String? linkedinUrl;
  final String? evidenceUrl;
  final String? confidence;
  final String? associationScope;
  final String? workEmail;

  bool get isHistorical => status == 'historical_role_needs_reconfirmation';

  String get verificationLabel => switch (status) {
    '2026_corporate_confirmed' => 'Cargo publicado por la empresa en 2026',
    '2026_industry_event_confirmed' =>
      'Cargo citado en un evento profesional de 2026',
    '2026_self_reported' => 'Función autodeclarada en 2026',
    'public_profile_2026_affiliation' =>
      'Perfil público, cargo exacto por confirmar',
    'historical_role_needs_reconfirmation' =>
      'Referencia histórica; vigencia por confirmar',
    _ => 'Fuente profesional por confirmar',
  };

  String? get associationLabel => switch (associationScope) {
    'parent_group_not_specific_subsidiary' =>
      'Pertenece al grupo empresarial; no se confirmó vínculo directo con esta filial.',
    'direct_company_current_function_unconfirmed' =>
      'Vinculación empresarial identificada; función actual de compras no confirmada.',
    'direct_mine_unit' => 'Referencia asociada a esta unidad minera.',
    _ => null,
  };

  Uri? get linkedinUri {
    final uri = Uri.tryParse(linkedinUrl ?? '');
    if (uri == null || uri.scheme != 'https') return null;
    if (uri.host != 'linkedin.com' && !uri.host.endsWith('.linkedin.com')) {
      return null;
    }
    return uri;
  }

  Uri? get evidenceUri {
    final uri = Uri.tryParse(evidenceUrl ?? '');
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? uri
        : null;
  }

  Uri? get workEmailUri {
    final value = (workEmail ?? '').trim();
    if (!RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$')
        .hasMatch(value)) {
      return null;
    }
    return Uri(scheme: 'mailto', path: value);
  }

  factory ProfessionalContact.fromJson(Map<String, dynamic> json) =>
      ProfessionalContact(
        name: json['name'] as String,
        role: json['role'] as String,
        status: json['status'] as String,
        reviewedOn: json['reviewed_on'] as String,
        department: json['department'] as String?,
        linkedinUrl: json['linkedin_url'] as String?,
        evidenceUrl: json['evidence_url'] as String?,
        confidence: json['confidence'] as String?,
        associationScope: json['association_scope'] as String?,
        workEmail: json['work_email'] as String?,
      );
}

class CompanyContact {
  const CompanyContact({
    this.name,
    this.role,
    this.phone,
    this.email,
    this.source,
    this.registryName,
    this.registryRole,
    this.registrySource,
    this.contactPage,
    this.reviewedOn,
    this.channelPurpose,
  });

  final String? name;
  final String? role;
  final String? phone;
  final String? email;
  final String? source;

  final String? registryName;
  final String? registryRole;
  final String? registrySource;
  final String? contactPage;
  final String? reviewedOn;
  final String? channelPurpose;

  Uri? get contactPageUri {
    final uri = Uri.tryParse(contactPage ?? '');
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? uri
        : null;
  }

  String? get channelPurposeLabel => switch (channelPurpose) {
    'supplier_presentations' => 'Recepción de presentaciones de proveedores',
    'office_switchboard' => 'Central de oficinas',
    'sales' || 'commercial_and_general' => 'Contacto comercial',
    'quotations' => 'Cotizaciones',
    'general_contact_form' => 'Formulario empresarial',
    'group_business_contact_form' => 'Contacto empresarial del grupo',
    'general_corporate' || 'general' ||
    'general_corporate_not_procurement' ||
    'general_office' ||
    'operations_office_not_purchasing' =>
      'Contacto general; no es una línea directa de compras',
    'corporate_switchboard' ||
    'shared_group_switchboard_not_direct_subsidiary' ||
    'group_supplier_support_and_shared_parent_switchboard' =>
      'Central del grupo; no acredita contacto con el comprador',
    'supplier_portal' ||
    'supplier_portal_parent_group_for_specific_mining_entity' ||
    'corporate_switchboard_and_supplier_portal' =>
      'Portal de proveedores (registro no realizado)',
    'supplier_registration_and_general' ||
    'general_corporate_and_supplier_registration' =>
      'Canal de proveedores y contacto general',
    'purchasing_public_request_and_general' =>
      'Correo de compras publicado en convocatoria',
    'general_customer_contact_and_supplier_portal' =>
      'Atención general y portal de proveedores',
    'commercial_customer_service_not_procurement' ||
    'general_customer_support' =>
      'Atención al cliente; no es contacto de compras',
    'general_corporate_administration_and_contact_form' =>
      'Administración y formulario general',
    'main_office_and_public_business_development_NOT_procurement' =>
      'Desarrollo de negocios; no es contacto de compras',
    'industry_event_company_representative' =>
      'Representación en evento profesional',
    'latin_america_office_and_global_general_mail' =>
      'Oficina regional y correo general',
    'general_email_published_2025' =>
      'Correo de directorio 2025; vigencia sin confirmar',
    'official_company_contact_page_address_only' =>
      'Página empresarial sin teléfono ni email',
    _ => null,
  };

  List<Uri> get emailUris =>
      RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}')
          .allMatches(email ?? '')
          .map((m) => m.group(0)!)
          .toSet()
          .map((value) => Uri(scheme: 'mailto', path: value))
          .toList(growable: false);

  bool get hasDirectContact =>
      (phone?.isNotEmpty ?? false) || (email?.isNotEmpty ?? false);

  bool get hasAny =>
      hasDirectContact ||
      (name?.isNotEmpty ?? false) ||
      (role?.isNotEmpty ?? false) ||
      (registryName?.isNotEmpty ?? false) ||
      contactPageUri != null;

  factory CompanyContact.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CompanyContact();

    return CompanyContact(
      name: json['name'] as String?,
      role: json['role'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      source: json['source'] as String?,
      registryName: json['registry_name'] as String?,
      registryRole: json['registry_role'] as String?,
      registrySource: json['registry_source'] as String?,
      contactPage: json['contact_page'] as String?,
      reviewedOn: json['reviewed_on'] as String?,
      channelPurpose: json['channel_purpose'] as String?,
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
    required this.internalPotential,
    required this.auroraProducts,
    required this.sigmaProducts,
    required this.contact,
    required this.commercial,
    required this.source,
    required this.sourceUpdatedAt,
    this.managementStatus,
    this.people = const [],
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

  /// Solo ranking interno. Nunca mostrar el número al vendedor.
  final double internalPotential;

  final List<String> auroraProducts;
  final List<String> sigmaProducts;
  final CompanyContact contact;
  final CommercialProfile commercial;
  final List<ProfessionalContact> people;
  final String source;
  final DateTime sourceUpdatedAt;
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
    ].any((value) => normalize(value).contains(term));
  }

  String get addressTypeLabel => verifiedHqAddress?.isNotEmpty == true
      ? 'HQ verificada'
      : 'Domicilio fiscal';

  factory Company.fromJson(Map<String, dynamic> json) {
    final commercialJson = json['commercial'] as Map<String, dynamic>?;
    final commercial = CommercialProfile.fromJson(commercialJson);
    final sector = (json['sector'] as String?) ?? 'Industrial';
    final verifiedHqAddress =
        (commercialJson?['address_hq_verified'] as String?) ??
        (json['address_hq_verified'] as String?);
    final fiscalAddress = json['fiscal_address'] as String?;
    final address =
        verifiedHqAddress ??
        fiscalAddress ??
        (json['address'] as String?) ??
        '';

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

    final score = (commercialJson?['score'] ?? json['score']) as num?;

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
      internalPotential: json['internal_potential'] != null
          ? (json['internal_potential'] as num).toDouble()
          : score != null
              ? score.toDouble() / 100
              : 0,
      auroraProducts: List<String>.from(
        json['aurora_products'] as List<dynamic>? ?? const [],
      ),
      sigmaProducts: List<String>.from(
        json['sigma_products'] as List<dynamic>? ?? const [],
      ),
      contact: contact,
      commercial: commercial,
      people: (json['people'] as List<dynamic>? ?? const [])
          .map(
            (row) => ProfessionalContact.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(growable: false),
      source:
          (json['source'] as String?) ??
          commercial.companySource ??
          'Dataset maestro Nexo',
      sourceUpdatedAt:
          DateTime.tryParse(
            (json['source_updated_at'] ??
                        commercial.sourceDate ??
                        json['fiscal_address_as_of'])
                    as String? ??
                '',
          ) ??
          DateTime(2026, 11, 9),
      managementStatus: json['management_status'] as String?,
    );
  }
}
