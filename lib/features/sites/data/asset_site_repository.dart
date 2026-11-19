import '../../companies/data/asset_company_repository.dart';
import '../../knowledge/data/asset_knowledge_repository.dart';
import '../../knowledge/domain/knowledge.dart';
import '../domain/site.dart';

class AssetSiteRepository {
  const AssetSiteRepository({
    this.companyRepository = const AssetCompanyRepository(),
    this.knowledgeRepository = const AssetKnowledgeRepository(),
  });

  final AssetCompanyRepository companyRepository;
  final AssetKnowledgeRepository knowledgeRepository;

  Future<SiteSnapshot> loadSnapshot() async {
    final companies = await companyRepository.loadCompanies();
    final knowledge = await knowledgeRepository.loadSnapshot();

    final locationClaims = <String, KnowledgeClaim>{};
    for (final claim in knowledge.claimsWhere('organization.location')) {
      if (claim.subject.type != KnowledgeSubjectType.organization) {
        throw FormatException(
          'Location claim must belong to an organization: ${claim.id}',
        );
      }
      if (locationClaims.containsKey(claim.subject.id)) {
        throw FormatException(
          'Duplicate organization location claim: ${claim.subject.id}',
        );
      }
      locationClaims[claim.subject.id] = claim;
    }

    final sites = <Site>[];
    final placements = <Placement>[];
    final gaps = <KnowledgeGap>[];
    final siteIds = <String>{};
    final placementIds = <String>{};

    for (final company in companies) {
      final claim = locationClaims[company.ruc];
      if (claim == null) {
        throw FormatException(
          'Missing organization location claim for RUC: ${company.ruc}',
        );
      }

      final value = claim.value;
      if (value is! Map<String, Object?>) {
        throw FormatException('Invalid location claim payload: ${claim.id}');
      }

      final latitude = (value['latitude'] as num?)?.toDouble();
      final longitude = (value['longitude'] as num?)?.toDouble();
      if (latitude == null || longitude == null) {
        throw FormatException('Location claim without coordinates: ${claim.id}');
      }

      final hasVerifiedHq =
          (company.verifiedHqAddress?.trim().isNotEmpty ?? false);
      final hasFiscalAddress =
          (company.fiscalAddress?.trim().isNotEmpty ?? false);

      final identityBasis = hasVerifiedHq
          ? SiteIdentityBasis.verifiedHeadquartersAddress
          : hasFiscalAddress
              ? SiteIdentityBasis.fiscalAddress
              : SiteIdentityBasis.geographicReference;

      final displayLabel = hasVerifiedHq
          ? company.verifiedHqAddress!.trim()
          : hasFiscalAddress
              ? company.fiscalAddress!.trim()
              : _areaLabel(value);

      final siteId = 'site:${company.ruc}:reference-1';
      if (!siteIds.add(siteId)) {
        throw FormatException('Duplicate site id: $siteId');
      }

      sites.add(
        Site(
          id: siteId,
          organizationRuc: company.ruc,
          displayLabel: displayLabel,
          function:
              hasVerifiedHq ? SiteFunction.headquarters : SiteFunction.unknown,
          identityBasis: identityBasis,
          operationalStatus: SiteOperationalStatus.unknown,
          sourceClaimId: claim.id,
        ),
      );

      final placementId = 'placement:$siteId:current';
      if (!placementIds.add(placementId)) {
        throw FormatException('Duplicate placement id: $placementId');
      }

      final placement = Placement(
        id: placementId,
        siteId: siteId,
        latitude: latitude,
        longitude: longitude,
        quality: PlacementQuality.fromKnowledgeValue(
          value['location_quality'],
        ),
        confidence: claim.confidence,
        nearbyRankingEligible:
            value['nearby_ranking_eligible'] as bool? ?? false,
        navigationEligible:
            value['navigation_eligible'] as bool? ?? false,
        sourceClaimId: claim.id,
        evidenceIds: List.unmodifiable(claim.evidenceIds),
        address: displayLabel,
        district: _nullableText(value['district']),
        province: _nullableText(value['province']),
        department: _nullableText(value['department']),
        asOf: claim.asOf,
      );

      if (!placement.hasValidCoordinates) {
        throw FormatException('Invalid placement coordinates: $placementId');
      }
      if (placement.navigationEligible && !placement.nearbyRankingEligible) {
        throw FormatException(
          'Navigation cannot bypass nearby eligibility: $placementId',
        );
      }
      placements.add(placement);

      gaps.add(
        KnowledgeGap(
          id: 'gap:organization:${company.ruc}:operational-site',
          subject: KnowledgeSubjectRef(
            type: KnowledgeSubjectType.organization,
            id: company.ruc,
          ),
          predicate: 'organization.operational_site',
          reason: KnowledgeGapReason.unknown,
          metadata: const {
            'meaning':
                'Current address/placement does not prove an operating industrial site.',
          },
        ),
      );
    }

    final knownSiteIds = sites.map((site) => site.id).toSet();
    if (!placements.every((placement) => knownSiteIds.contains(placement.siteId))) {
      throw const FormatException('Every placement must reference an existing site.');
    }

    return SiteSnapshot(
      sites: sites,
      placements: placements,
      gaps: gaps,
    );
  }
}

String _areaLabel(Map<String, Object?> value) {
  final parts = [
    _nullableText(value['district']),
    _nullableText(value['province']),
    _nullableText(value['department']),
  ].whereType<String>().toList(growable: false);

  return parts.isEmpty ? 'Ubicación de referencia' : parts.join(', ');
}

String? _nullableText(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}
