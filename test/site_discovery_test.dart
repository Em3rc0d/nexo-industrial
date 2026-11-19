import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/knowledge/domain/knowledge.dart';
import 'package:nexo_industrial/features/sites/data/operational_site_verification_repository.dart';
import 'package:nexo_industrial/features/sites/data/site_discovery_repository.dart';
import 'package:nexo_industrial/features/sites/domain/site.dart';
import 'package:nexo_industrial/features/sites/domain/site_discovery.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('production discovery creates exactly one additional Site identity', () async {
    final result = await const AssetSiteDiscoveryRepository().loadSnapshot();

    expect(result.discoveries, hasLength(1));
    expect(result.snapshot.sites, hasLength(1908));
    expect(result.snapshot.placements, hasLength(1907));
    expect(result.claims, hasLength(1));
    expect(result.evidence, hasLength(1));
  });

  test('Explomin keeps reference Site and gains a separate discovered headquarters', () async {
    final result = await const AssetSiteDiscoveryRepository().loadSnapshot();
    final sites = result.snapshot
        .sitesForOrganization('20501523837')
        .toList(growable: false);

    expect(sites, hasLength(2));

    final reference =
        sites.singleWhere((site) => site.id == 'site:20501523837:reference-1');
    final discovered =
        sites.singleWhere((site) => site.id == 'site:20501523837:hq-conchan-1');

    expect(reference.identityBasis, SiteIdentityBasis.fiscalAddress);
    expect(reference.operationalStatus, SiteOperationalStatus.unknown);

    expect(discovered.identityBasis, SiteIdentityBasis.discoveredEvidence);
    expect(discovered.function, SiteFunction.headquarters);
    expect(discovered.operationalStatus, SiteOperationalStatus.unknown);
    expect(
      discovered.displayLabel,
      'Panamericana Sur Km. 22 Huertos de Conchán - Lima, 15842',
    );
  });

  test('discovered Site identity does not fabricate a coordinate Placement', () async {
    final result = await const AssetSiteDiscoveryRepository().loadSnapshot();
    const siteId = 'site:20501523837:hq-conchan-1';

    expect(result.snapshot.placementsForSite(siteId), isEmpty);
    expect(
      result.snapshot.gaps.where(
        (gap) =>
            gap.subject.type == KnowledgeSubjectType.site &&
            gap.subject.id == siteId &&
            gap.predicate == 'site.placement' &&
            gap.reason == KnowledgeGapReason.unknown,
      ),
      hasLength(1),
    );
  });

  test('site discovery emits an evidenced Site identity claim', () async {
    final result = await const AssetSiteDiscoveryRepository().loadSnapshot();

    final claim = result.claims.single;
    expect(claim.subject.type, KnowledgeSubjectType.site);
    expect(claim.subject.id, 'site:20501523837:hq-conchan-1');
    expect(claim.predicate, 'site.identity');
    expect(claim.origin, KnowledgeOrigin.declared);
    expect(claim.confidence, KnowledgeConfidence.high);
    expect(claim.evidenceIds, hasLength(1));

    final evidence = result.evidence.single;
    expect(evidence.sourceType, EvidenceSourceType.url);
    expect(evidence.locator, 'https://explomin.com/es/contacto/');
  });

  test('CONTRACT 021 verifies discovered Site while reference Site stays untouched', () async {
    final result =
        await const AssetOperationalSiteVerificationRepository().loadSnapshot();

    final explominSites = result.snapshot
        .sitesForOrganization('20501523837')
        .toList(growable: false);

    expect(explominSites, hasLength(2));

    final reference = explominSites
        .singleWhere((site) => site.id == 'site:20501523837:reference-1');
    final headquarters = explominSites
        .singleWhere((site) => site.id == 'site:20501523837:hq-conchan-1');

    expect(reference.operationalStatus, SiteOperationalStatus.unknown);
    expect(headquarters.operationalStatus, SiteOperationalStatus.confirmedOperational);
    expect(headquarters.function, SiteFunction.headquarters);

    expect(
      result.snapshot.sites.where((site) => site.isOperationallyConfirmed),
      hasLength(5),
    );
    expect(
      result.snapshot.gaps
          .where((gap) => gap.predicate == 'organization.operational_site'),
      hasLength(1902),
    );
  });

  test('engine rejects duplicate Site identity', () async {
    final baseline = await const AssetSiteDiscoveryRepository(
      overlayAssetPath: 'assets/data/sites.discovered.overlay.json',
    ).siteRepository.loadSnapshot();

    final discovery = SiteDiscoveryRecord(
      id: 'discovery:test:duplicate',
      siteId: baseline.sites.first.id,
      organizationRuc: baseline.sites.first.organizationRuc,
      displayLabel: 'Different label',
      function: SiteFunction.office,
      method: SiteDiscoveryMethod.manualReview,
      discoveredAt: DateTime.utc(2026, 11, 19),
      evidence: [
        EvidenceRef(
          id: 'evidence:test:duplicate-site',
          sourceType: EvidenceSourceType.url,
          locator: 'https://example.com/site',
        ),
      ],
    );

    expect(
      () => const SiteDiscoveryEngine().apply(baseline, [discovery]),
      throwsFormatException,
    );
  });

  test('engine rejects discovery without evidence', () async {
    final baseline = await const AssetSiteDiscoveryRepository().siteRepository.loadSnapshot();

    final discovery = SiteDiscoveryRecord(
      id: 'discovery:test:no-evidence',
      siteId: 'site:20501523837:test-no-evidence',
      organizationRuc: '20501523837',
      displayLabel: 'New Site',
      function: SiteFunction.office,
      method: SiteDiscoveryMethod.manualReview,
      discoveredAt: DateTime.utc(2026, 11, 19),
      evidence: const [],
    );

    expect(
      () => const SiteDiscoveryEngine().apply(baseline, [discovery]),
      throwsFormatException,
    );
  });
}
