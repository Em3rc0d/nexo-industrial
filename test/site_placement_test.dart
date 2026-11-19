import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/sites/data/asset_site_repository.dart';
import 'package:nexo_industrial/features/sites/domain/site.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SiteSnapshot snapshot;

  setUpAll(() async {
    snapshot = await const AssetSiteRepository().loadSnapshot();
  });

  test('projects one reference site and placement per canonical organization', () {
    expect(snapshot.sites, hasLength(1907));
    expect(snapshot.placements, hasLength(1907));
    expect(
      snapshot.sites.map((site) => site.organizationRuc).toSet(),
      hasLength(1907),
    );
    expect(
      snapshot.sites.map((site) => site.id).toSet(),
      hasLength(1907),
    );
    expect(
      snapshot.placements.map((placement) => placement.id).toSet(),
      hasLength(1907),
    );
  });

  test('does not pretend current addresses are confirmed operational sites', () {
    expect(
      snapshot.sites.every(
        (site) => site.operationalStatus == SiteOperationalStatus.unknown,
      ),
      isTrue,
    );
    expect(
      snapshot.sites.where((site) => site.isOperationallyConfirmed),
      isEmpty,
    );

    final gaps = snapshot.gaps
        .where((gap) => gap.predicate == 'organization.operational_site')
        .toList(growable: false);
    expect(gaps, hasLength(1907));
  });

  test('placement keeps audited geography semantics', () {
    final byQuality = <PlacementQuality, int>{};
    for (final placement in snapshot.placements) {
      byQuality.update(
        placement.quality,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    expect(byQuality[PlacementQuality.exactAddress], 334);
    expect(byQuality[PlacementQuality.addressReference], 36);
    expect(byQuality[PlacementQuality.interpolatedAddress], 137);
    expect(byQuality[PlacementQuality.streetReference], 551);
    expect(byQuality[PlacementQuality.districtReference], 849);

    expect(
      snapshot.placements.where((p) => p.nearbyRankingEligible),
      hasLength(370),
    );
    expect(
      snapshot.placements.where((p) => p.navigationEligible),
      hasLength(370),
    );
  });

  test('current interpolated placements remain non-actionable for proximity', () {
    final interpolated = snapshot.placements
        .where((p) => p.quality == PlacementQuality.interpolatedAddress)
        .toList(growable: false);

    expect(interpolated, hasLength(137));
    expect(
      interpolated.every(
        (p) => !p.nearbyRankingEligible && !p.navigationEligible,
      ),
      isTrue,
    );
  });

  test('every placement references an existing site and evidence-backed claim', () {
    final siteIds = snapshot.sites.map((site) => site.id).toSet();

    expect(
      snapshot.placements.every(
        (placement) =>
            siteIds.contains(placement.siteId) &&
            placement.sourceClaimId.startsWith('claim:organization:') &&
            placement.evidenceIds.isNotEmpty,
      ),
      isTrue,
    );
  });

  test('verified HQ can identify a headquarters reference without proving operation', () {
    final verifiedHqSites = snapshot.sites
        .where(
          (site) =>
              site.identityBasis ==
              SiteIdentityBasis.verifiedHeadquartersAddress,
        )
        .toList(growable: false);

    expect(verifiedHqSites, isNotEmpty);
    expect(
      verifiedHqSites.every(
        (site) =>
            site.function == SiteFunction.headquarters &&
            site.operationalStatus == SiteOperationalStatus.unknown,
      ),
      isTrue,
    );
  });
}
