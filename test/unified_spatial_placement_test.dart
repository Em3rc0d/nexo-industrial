import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/sites/data/property_facility_repository.dart';
import 'package:nexo_industrial/features/sites/data/site_identity_reconciliation_repository.dart';
import 'package:nexo_industrial/features/sites/data/unified_spatial_placement_repository.dart';
import 'package:nexo_industrial/features/sites/domain/property_facility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CONTRACT 028 migrates every active Site Placement losslessly', () async {
    final legacy =
        await const AssetSiteIdentityReconciliationRepository().loadSnapshot();
    final unified =
        await const UnifiedSpatialPlacementRepository().loadSnapshot();

    expect(legacy.snapshot.placements, hasLength(1907));
    expect(unified.legacySitePlacementCount, 1907);
    expect(unified.sitePlacements, hasLength(1907));
    expect(unified.placements, hasLength(1908));

    final byId = {
      for (final placement in unified.sitePlacements) placement.id: placement,
    };

    for (final source in legacy.snapshot.placements) {
      final migrated = byId[source.id];
      expect(migrated, isNotNull, reason: source.id);
      expect(migrated!.entityType, SpatialEntityType.site);
      expect(migrated.entityId, source.siteId);
      expect(migrated.latitude, source.latitude);
      expect(migrated.longitude, source.longitude);
      expect(migrated.quality, source.quality);
      expect(migrated.confidence, source.confidence);
      expect(migrated.mapDisplayEligible, source.mapDisplayEligible);
      expect(migrated.nearbyRankingEligible, source.nearbyRankingEligible);
      expect(migrated.navigationEligible, source.navigationEligible);
      expect(migrated.sourceClaimId, source.sourceClaimId);
      expect(migrated.evidenceIds, source.evidenceIds);
      expect(migrated.address, source.address);
      expect(migrated.district, source.district);
      expect(migrated.province, source.province);
      expect(migrated.department, source.department);
      expect(migrated.asOf, source.asOf);
    }
  });

  test('unified authority preserves production eligibility counts', () async {
    final unified =
        await const UnifiedSpatialPlacementRepository().loadSnapshot();

    expect(
      unified.sitePlacements.where((p) => p.mapDisplayEligible),
      hasLength(1907),
    );
    expect(
      unified.sitePlacements.where((p) => p.nearbyRankingEligible),
      hasLength(370),
    );
    expect(
      unified.sitePlacements.where((p) => p.navigationEligible),
      hasLength(370),
    );
  });

  test('ANA well remains a non-actionable Asset Placement', () async {
    final unified =
        await const UnifiedSpatialPlacementRepository().loadSnapshot();
    final property =
        await const AssetPropertyFacilityRepository().loadSnapshot();

    expect(unified.nonSitePlacementCount, 1);
    final ana = unified.placements.singleWhere(
      (p) =>
          p.entityType == SpatialEntityType.asset &&
          p.entityId ==
              'asset:20501523837:mz-b-lote-1:groundwater-well',
    );

    expect(ana.latitude, closeTo(-12.239774, 1e-9));
    expect(ana.longitude, closeTo(-76.952451, 1e-9));
    expect(ana.mapDisplayEligible, isFalse);
    expect(ana.nearbyRankingEligible, isFalse);
    expect(ana.navigationEligible, isFalse);
    expect(ana.entityId, isNot('site:20501523837:reference-1'));

    expect(property.placements.single.id, ana.id);
  });

  test('no Site identity or Placement ownership regression is introduced', () async {
    final sites =
        await const AssetSiteIdentityReconciliationRepository().loadSnapshot();
    final unified =
        await const UnifiedSpatialPlacementRepository().loadSnapshot();

    expect(sites.snapshot.sites, hasLength(1907));
    expect(sites.aliases, hasLength(1));
    expect(
      sites.snapshot.sitesForOrganization('20501523837'),
      hasLength(1),
    );
    expect(
      unified.placementsForEntity(
        SpatialEntityType.site,
        'site:20501523837:hq-conchan-1',
      ),
      isEmpty,
    );
  });
}
