import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/knowledge/domain/knowledge.dart';
import 'package:nexo_industrial/features/sites/data/site_discovery_repository.dart';
import 'package:nexo_industrial/features/sites/data/site_identity_reconciliation_repository.dart';
import 'package:nexo_industrial/features/sites/domain/site.dart';
import 'package:nexo_industrial/features/sites/domain/site_identity_reconciliation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const reference = 'site:20501523837:reference-1';
  const discovered = 'site:20501523837:hq-conchan-1';

  test('production reconciliation collapses one duplicate Site identity', () async {
    final result =
        await const AssetSiteIdentityReconciliationRepository().loadSnapshot();

    expect(result.reconciliations, hasLength(1));
    expect(result.aliases, hasLength(1));
    expect(result.claims, hasLength(1));
    expect(result.evidence, hasLength(2));

    expect(result.snapshot.sites, hasLength(1907));
    expect(result.snapshot.placements, hasLength(1907));
  });

  test('Explomin canonical Site preserves identity, placement and HQ semantics', () async {
    final result =
        await const AssetSiteIdentityReconciliationRepository().loadSnapshot();

    final sites =
        result.snapshot.sitesForOrganization('20501523837').toList(growable: false);
    expect(sites, hasLength(1));

    final canonical = sites.single;
    expect(canonical.id, reference);
    expect(canonical.identityBasis, SiteIdentityBasis.fiscalAddress);
    expect(canonical.function, SiteFunction.headquarters);
    expect(result.snapshot.siteById(discovered), isNull);

    final placements =
        result.snapshot.placementsForSite(reference).toList(growable: false);
    expect(placements, hasLength(1));
    expect(placements.single.quality, PlacementQuality.districtReference);
    expect(placements.single.nearbyRankingEligible, isFalse);
    expect(placements.single.navigationEligible, isFalse);
  });

  test('alias metadata preserves discovered label and canonical mapping', () async {
    final result =
        await const AssetSiteIdentityReconciliationRepository().loadSnapshot();

    final alias = result.aliases.single;
    expect(alias.aliasSiteId, discovered);
    expect(alias.canonicalSiteId, reference);
    expect(
      alias.aliasLabel,
      'Panamericana Sur Km. 22 Huertos de Conchán - Lima, 15842',
    );
    expect(result.canonicalSiteIdFor(discovered), reference);
    expect(result.canonicalSiteIdFor(reference), reference);
  });

  test('reconciliation emits evidenced derived SAME_SITE claim', () async {
    final result =
        await const AssetSiteIdentityReconciliationRepository().loadSnapshot();

    final claim = result.claims.single;
    expect(claim.subject.type, KnowledgeSubjectType.site);
    expect(claim.subject.id, reference);
    expect(claim.predicate, 'site.identity_relation');
    expect(claim.origin, KnowledgeOrigin.derived);
    expect(claim.confidence, KnowledgeConfidence.high);
    expect(claim.evidenceIds, hasLength(2));

    final value = claim.value as Map<String, Object?>;
    expect(value['relation'], 'same_site');
    expect(value['canonical_site_id'], reference);
  });

  test('reconciliation removes only redundant alias placement gap', () async {
    final discovery = await const AssetSiteDiscoveryRepository().loadSnapshot();
    expect(
      discovery.snapshot.gaps.where(
        (gap) =>
            gap.subject.type == KnowledgeSubjectType.site &&
            gap.subject.id == discovered &&
            gap.predicate == 'site.placement',
      ),
      hasLength(1),
    );

    final result =
        await const AssetSiteIdentityReconciliationRepository().loadSnapshot();
    expect(
      result.snapshot.gaps.any(
        (gap) =>
            gap.subject.type == KnowledgeSubjectType.site &&
            gap.subject.id == discovered,
      ),
      isFalse,
    );
  });

  test('audit keeps ANA Lote 1 relationship UNKNOWN and performs no outreach', () async {
    final raw = await rootBundle.loadString(
      'data/site_enrichment/2026-11-19_site_identity_reconciliation.json',
    );
    final document = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final assessments = (document['assessments'] as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);

    expect(document['outreach_performed'], isFalse);
    expect(assessments, hasLength(2));
    expect(
      assessments.where((row) => row['outcome'] == 'same_site'),
      hasLength(1),
    );
    expect(
      assessments.where((row) => row['outcome'] == 'unknown'),
      hasLength(1),
    );

    final ana = assessments.singleWhere(
      (row) =>
          row['right_ref'] == 'external:ana:explomin:mz-b-lote-1:2024',
    );
    expect(ana['outcome'], 'unknown');
    expect(ana['canonical_site_id'], isNull);
  });

  test('SAME_SITE fails without valid canonical Site', () async {
    final baseline = (await const AssetSiteDiscoveryRepository().loadSnapshot()).snapshot;

    final record = SiteIdentityReconciliationRecord(
      id: 'reconciliation:test:no-canonical',
      organizationRuc: '20501523837',
      leftSiteId: reference,
      rightSiteId: discovered,
      relation: SiteIdentityRelation.sameSite,
      method: SiteIdentityReconciliationMethod.manualReview,
      confidence: KnowledgeConfidence.medium,
      reviewedAt: DateTime.utc(2026, 11, 19),
      evidence: [
        EvidenceRef(
          id: 'evidence:test:reconciliation',
          sourceType: EvidenceSourceType.url,
          locator: 'https://example.com/reconciliation',
        ),
      ],
    );

    expect(
      () => const SiteIdentityReconciliationEngine().apply(baseline, [record]),
      throwsFormatException,
    );
  });

  test('SAME_SITE cannot absorb a Site that already owns Placement', () async {
    final baseline = (await const AssetSiteDiscoveryRepository().loadSnapshot()).snapshot;

    final record = SiteIdentityReconciliationRecord(
      id: 'reconciliation:test:wrong-canonical',
      organizationRuc: '20501523837',
      leftSiteId: reference,
      rightSiteId: discovered,
      relation: SiteIdentityRelation.sameSite,
      canonicalSiteId: discovered,
      method: SiteIdentityReconciliationMethod.manualReview,
      confidence: KnowledgeConfidence.medium,
      reviewedAt: DateTime.utc(2026, 11, 19),
      evidence: [
        EvidenceRef(
          id: 'evidence:test:wrong-canonical',
          sourceType: EvidenceSourceType.url,
          locator: 'https://example.com/reconciliation',
        ),
      ],
    );

    expect(
      () => const SiteIdentityReconciliationEngine().apply(baseline, [record]),
      throwsFormatException,
    );
  });

  test('UNKNOWN relation preserves both Site identities', () async {
    final baseline = (await const AssetSiteDiscoveryRepository().loadSnapshot()).snapshot;

    final record = SiteIdentityReconciliationRecord(
      id: 'reconciliation:test:unknown',
      organizationRuc: '20501523837',
      leftSiteId: reference,
      rightSiteId: discovered,
      relation: SiteIdentityRelation.unknown,
      method: SiteIdentityReconciliationMethod.manualReview,
      confidence: KnowledgeConfidence.unknown,
      reviewedAt: DateTime.utc(2026, 11, 19),
      evidence: [
        EvidenceRef(
          id: 'evidence:test:unknown-relation',
          sourceType: EvidenceSourceType.url,
          locator: 'https://example.com/unknown',
        ),
      ],
    );

    final result =
        const SiteIdentityReconciliationEngine().apply(baseline, [record]);

    expect(result.snapshot.sites, hasLength(1908));
    expect(result.aliases, isEmpty);
    expect(result.snapshot.siteById(reference), isNotNull);
    expect(result.snapshot.siteById(discovered), isNotNull);
  });
}
