import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/knowledge/domain/knowledge.dart';
import 'package:nexo_industrial/features/sites/data/asset_site_repository.dart';
import 'package:nexo_industrial/features/sites/data/operational_site_verification_repository.dart';
import 'package:nexo_industrial/features/sites/domain/site.dart';
import 'package:nexo_industrial/features/sites/domain/site_verification.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SiteSnapshot baseline;
  late Site firstSite;

  setUpAll(() async {
    baseline = await const AssetSiteRepository().loadSnapshot();
    firstSite = baseline.sites.first;
  });

  OperationalSiteVerification verification({
    OperationalSiteDecision decision = OperationalSiteDecision.operational,
    SiteFunction function = SiteFunction.plant,
    OperationalSiteVerificationMethod method =
        OperationalSiteVerificationMethod.publicSource,
    String? organizationRuc,
    String? siteId,
    List<EvidenceRef>? evidence,
    DateTime? validFrom,
    DateTime? validUntil,
  }) {
    return OperationalSiteVerification(
      id: 'verification:test:1',
      siteId: siteId ?? firstSite.id,
      organizationRuc: organizationRuc ?? firstSite.organizationRuc,
      decision: decision,
      function: function,
      method: method,
      verifiedAt: DateTime.utc(2026, 11, 19),
      validFrom: validFrom,
      validUntil: validUntil,
      reviewer: 'test',
      notes: 'Controlled verification fixture.',
      evidence: evidence ??
          [
            EvidenceRef(
              id: 'evidence:test:site:1',
              sourceType: EvidenceSourceType.url,
              locator: 'https://example.com/verified-site',
              reviewedAt: DateTime.utc(2026, 11, 19),
              summary: 'Controlled fixture evidence.',
            ),
          ],
    );
  }

  test('production overlay applies evidence-backed verification semantics', () async {
    final result =
        await const AssetOperationalSiteVerificationRepository().loadSnapshot();

    expect(result.claims, hasLength(result.verifications.length));
    expect(
      result.claims.every(
        (claim) =>
            claim.predicate == 'site.operational_status' &&
            claim.evidenceIds.isNotEmpty,
      ),
      isTrue,
    );

    final operationalOrganizations = result.verifications
        .where(
          (verification) =>
              verification.decision == OperationalSiteDecision.operational,
        )
        .map((verification) => verification.organizationRuc)
        .toSet();

    expect(
      result.snapshot.sites.where((site) => site.isOperationallyConfirmed),
      hasLength(operationalOrganizations.length),
    );
    expect(
      result.snapshot.gaps
          .where((gap) => gap.predicate == 'organization.operational_site'),
      hasLength(1907 - operationalOrganizations.length),
    );
  });

  test('operational verification preserves site identity and resolves one org gap', () {
    final result = const SiteVerificationEngine().apply(
      baseline,
      [verification()],
    );

    final updated = result.snapshot.siteById(firstSite.id)!;
    expect(updated.id, firstSite.id);
    expect(updated.organizationRuc, firstSite.organizationRuc);
    expect(updated.operationalStatus, SiteOperationalStatus.confirmedOperational);
    expect(updated.function, SiteFunction.plant);

    expect(
      result.snapshot.gaps
          .where((gap) => gap.predicate == 'organization.operational_site'),
      hasLength(1906),
    );
    expect(
      result.snapshot.gaps.any(
        (gap) =>
            gap.predicate == 'organization.operational_site' &&
            gap.subject.id == firstSite.organizationRuc,
      ),
      isFalse,
    );
  });

  test('not-operational verification does not claim organization lacks other sites', () {
    final result = const SiteVerificationEngine().apply(
      baseline,
      [
        verification(
          decision: OperationalSiteDecision.notOperational,
          function: SiteFunction.unknown,
        ),
      ],
    );

    final updated = result.snapshot.siteById(firstSite.id)!;
    expect(
      updated.operationalStatus,
      SiteOperationalStatus.confirmedNotOperational,
    );
    expect(
      result.snapshot.gaps
          .where((gap) => gap.predicate == 'organization.operational_site'),
      hasLength(1907),
    );
  });

  test('verification emits an evidenced site knowledge claim', () {
    final result = const SiteVerificationEngine().apply(
      baseline,
      [
        verification(
          method: OperationalSiteVerificationMethod.fieldObservation,
        ),
      ],
    );

    expect(result.claims, hasLength(1));
    final claim = result.claims.single;
    expect(claim.subject.type, KnowledgeSubjectType.site);
    expect(claim.subject.id, firstSite.id);
    expect(claim.predicate, 'site.operational_status');
    expect(claim.origin, KnowledgeOrigin.observed);
    expect(claim.confidence, KnowledgeConfidence.high);
    expect(claim.evidenceIds, ['evidence:test:site:1']);
    expect(result.evidence, hasLength(1));
  });

  test('rejects operational verification without evidence', () {
    expect(
      () => const SiteVerificationEngine().apply(
        baseline,
        [verification(evidence: const [])],
      ),
      throwsFormatException,
    );
  });

  test('rejects operational verification without concrete site function', () {
    expect(
      () => const SiteVerificationEngine().apply(
        baseline,
        [verification(function: SiteFunction.unknown)],
      ),
      throwsFormatException,
    );
  });

  test('rejects verification whose organization does not own the site', () {
    expect(
      () => const SiteVerificationEngine().apply(
        baseline,
        [verification(organizationRuc: '00000000000')],
      ),
      throwsFormatException,
    );
  });

  test('rejects invalid validity ranges', () {
    expect(
      () => const SiteVerificationEngine().apply(
        baseline,
        [
          verification(
            validFrom: DateTime.utc(2026, 12, 1),
            validUntil: DateTime.utc(2026, 11, 30),
          ),
        ],
      ),
      throwsFormatException,
    );
  });

  test('rejects multiple current verifications for the same site', () {
    final first = verification();
    final second = OperationalSiteVerification(
      id: 'verification:test:2',
      siteId: first.siteId,
      organizationRuc: first.organizationRuc,
      decision: OperationalSiteDecision.operational,
      function: SiteFunction.warehouse,
      method: OperationalSiteVerificationMethod.officialSource,
      verifiedAt: DateTime.utc(2026, 11, 19),
      evidence: [
        EvidenceRef(
          id: 'evidence:test:site:2',
          sourceType: EvidenceSourceType.url,
          locator: 'https://example.com/verified-site-2',
        ),
      ],
    );

    expect(
      () => const SiteVerificationEngine().apply(baseline, [first, second]),
      throwsFormatException,
    );
  });
}
