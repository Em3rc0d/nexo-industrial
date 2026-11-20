import '../../companies/data/asset_company_repository.dart';
import '../../companies/domain/company.dart';
import '../domain/property_facility.dart';
import '../domain/runtime_spatial_projection.dart';
import '../domain/spatial_exposure.dart';
import 'site_identity_reconciliation_repository.dart';
import 'spatial_exposure_repository.dart';

class RuntimeSpatialProjectionRepository {
  const RuntimeSpatialProjectionRepository({
    this.companyRepository = const AssetCompanyRepository(),
    this.siteRepository = const AssetSiteIdentityReconciliationRepository(),
    this.exposureRepository = const SpatialExposureRepository(),
  });

  final AssetCompanyRepository companyRepository;
  final AssetSiteIdentityReconciliationRepository siteRepository;
  final SpatialExposureRepository exposureRepository;

  Future<RuntimeSpatialProjectionSnapshot> loadSnapshot() async {
    final companies = await companyRepository.loadCompanies();
    final sites = await siteRepository.loadSnapshot();
    final exposure = await exposureRepository.loadSnapshot();

    final companyByRuc = <String, Company>{
      for (final company in companies) company.ruc: company,
    };
    final siteById = {
      for (final site in sites.snapshot.sites) site.id: site,
    };
    final decisionByKey = {
      for (final decision in exposure.decisions)
        '${decision.placementId}|${decision.surface.name}': decision,
    };

    final views = <RuntimeCompanySpatialView>[];
    final companyIds = <String>{};

    for (final placement in exposure.spatial.placements) {
      if (placement.entityType != SpatialEntityType.site) continue;

      final site = siteById[placement.entityId];
      if (site == null) {
        throw FormatException(
          'Runtime projection cannot resolve Site: ${placement.entityId}',
        );
      }
      final company = companyByRuc[site.organizationRuc];
      if (company == null) {
        throw FormatException(
          'Runtime projection cannot resolve Company RUC: ${site.organizationRuc}',
        );
      }

      SpatialExposureDecision decision(SpatialExposureSurface surface) {
        final value = decisionByKey['${placement.id}|${surface.name}'];
        if (value == null) {
          throw FormatException(
            'Missing runtime exposure decision for ${placement.id} / ${surface.name}',
          );
        }
        return value;
      }

      final view = RuntimeCompanySpatialView(
        company: company,
        siteId: site.id,
        placement: placement,
        mapExposure: decision(SpatialExposureSurface.commercialMap),
        detailExposure: decision(SpatialExposureSurface.companyDetail),
        nearbyExposure: decision(SpatialExposureSurface.nearbyRanking),
        navigationExposure: decision(SpatialExposureSurface.navigation),
      );

      if (!view.mapVisible) continue;
      if (!companyIds.add(company.id)) {
        throw FormatException(
          'CONTRACT 030 requires one primary map Site per Company: ${company.id}',
        );
      }
      views.add(view);
    }

    if (views.length != companies.length) {
      throw FormatException(
        'Runtime spatial projection coverage mismatch: '
        '${views.length} views for ${companies.length} companies.',
      );
    }

    return RuntimeSpatialProjectionSnapshot(
      companies: companies,
      spatialViews: views,
    );
  }
}
