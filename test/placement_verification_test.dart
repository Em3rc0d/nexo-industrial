import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/knowledge/domain/knowledge.dart';
import 'package:nexo_industrial/features/sites/data/placement_verification_repository.dart';
import 'package:nexo_industrial/features/sites/data/site_discovery_repository.dart';
import 'package:nexo_industrial/features/sites/domain/placement_verification.dart';
import 'package:nexo_industrial/features/sites/domain/site.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SiteSnapshot baseline;
  const explominHq = 'site:20501523837:hq-conchan-1';

  setUpAll(() async {
    baseline = (await const AssetSiteDiscoveryRepository().loadSnapshot()).snapshot;
  });

  PlacementVerificationRecord acceptedForDiscoveredSite({
    PlacementQuality quality = PlacementQuality.addressReference,
    bool nearby = false,
    bool navigation = false,
    List<EvidenceRef>? evidence,
  }) {
    return PlacementVerificationRecord(
      id: 'placement-verification:test:explomin-hq',
      siteId: explominHq,
      latitude: -12.239774,
      longitude: -76.952451,
      quality: quality,
      confidence: KnowledgeConfidence.medium,
      method: PlacementVerificationMethod.manualReview,
      verifiedAt: DateTime.utc(2026, 11, 19),
      nearbyRankingEligible: nearby,
      navigationEligible: navigation,
      address: 'Controlled fixture address',
      evidence: evidence ??
          [
            EvidenceRef(
              id: 'evidence:test:placement',
              sourceType: EvidenceSourceType.url,
              locator: 'https://example.com/placement-evidence',
            ),
          ],
    );
  }

  test('production placement overlay remains fail-closed after reconciliation', () async {
    final result = await const AssetPlacementVerificationRepository().loadSnapshot();

    expect(result.verifications, isEmpty);
    expect(result.claims, isEmpty);
    expect(result.evidence, isEmpty);
    expect(result.snapshot.sites, hasLength(1907));
    expect(result.snapshot.placements, hasLength(1907));
    expect(result.snapshot.siteById(explominHq), isNull);
    expect(
      result.snapshot.placementsForSite('site:20501523837:reference-1'),
      hasLength(1),
    );
    expect(
      result.snapshot.gaps.any(
        (gap) =>
            gap.subject.type == KnowledgeSubjectType.site &&
            gap.subject.id == explominHq,
      ),
      isFalse,
    );
  });

  test('accepted placement can resolve a discovered Site placement gap', () {
    final result = const PlacementVerificationEngine().apply(
      baseline,
      [acceptedForDiscoveredSite()],
    );

    final placements =
        result.snapshot.placementsForSite(explominHq).toList(growable: false);
    expect(placements, hasLength(1));
    expect(placements.single.latitude, closeTo(-12.239774, 1e-9));
    expect(placements.single.longitude, closeTo(-76.952451, 1e-9));
    expect(result.claims, hasLength(1));
    expect(result.claims.single.predicate, 'site.placement');
    expect(result.claims.single.evidenceIds, ['evidence:test:placement']);

    expect(
      result.snapshot.gaps.any(
        (gap) =>
            gap.subject.type == KnowledgeSubjectType.site &&
            gap.subject.id == explominHq &&
            gap.predicate == 'site.placement',
      ),
      isFalse,
    );
  });

  test('property reference can never enable proximity or navigation', () {
    expect(
      () => const PlacementVerificationEngine().apply(
        baseline,
        [
          acceptedForDiscoveredSite(
            quality: PlacementQuality.propertyReference,
            nearby: true,
          ),
        ],
      ),
      throwsFormatException,
    );

    expect(
      () => const PlacementVerificationEngine().apply(
        baseline,
        [
          acceptedForDiscoveredSite(
            quality: PlacementQuality.propertyReference,
            nearby: true,
            navigation: true,
          ),
        ],
      ),
      throwsFormatException,
    );
  });

  test('navigation eligibility cannot bypass nearby eligibility', () {
    expect(
      () => const PlacementVerificationEngine().apply(
        baseline,
        [
          acceptedForDiscoveredSite(
            navigation: true,
          ),
        ],
      ),
      throwsFormatException,
    );
  });

  test('verification rejects unknown Site and missing evidence', () {
    final unknownSite = PlacementVerificationRecord(
      id: 'placement-verification:test:unknown',
      siteId: 'site:20501523837:not-real',
      latitude: -12.2,
      longitude: -76.9,
      quality: PlacementQuality.addressReference,
      confidence: KnowledgeConfidence.medium,
      method: PlacementVerificationMethod.manualReview,
      verifiedAt: DateTime.utc(2026, 11, 19),
      nearbyRankingEligible: false,
      navigationEligible: false,
      evidence: [
        EvidenceRef(
          id: 'evidence:test:unknown',
          sourceType: EvidenceSourceType.url,
          locator: 'https://example.com/unknown',
        ),
      ],
    );

    expect(
      () => const PlacementVerificationEngine().apply(baseline, [unknownSite]),
      throwsFormatException,
    );

    expect(
      () => const PlacementVerificationEngine().apply(
        baseline,
        [acceptedForDiscoveredSite(evidence: const [])],
      ),
      throwsFormatException,
    );
  });

  test('replacing legacy placement requires explicit supersedes id', () {
    const siteId = 'site:20501523837:reference-1';
    final existing =
        baseline.placementsForSite(siteId).single;

    final withoutSupersedes = PlacementVerificationRecord(
      id: 'placement-verification:test:replace',
      siteId: siteId,
      latitude: -12.239774,
      longitude: -76.952451,
      quality: PlacementQuality.propertyReference,
      confidence: KnowledgeConfidence.medium,
      method: PlacementVerificationMethod.officialCoordinates,
      verifiedAt: DateTime.utc(2026, 11, 19),
      nearbyRankingEligible: false,
      navigationEligible: false,
      evidence: [
        EvidenceRef(
          id: 'evidence:test:replace',
          sourceType: EvidenceSourceType.url,
          locator: 'https://example.com/official-coordinate',
        ),
      ],
    );

    expect(
      () => const PlacementVerificationEngine().apply(
        baseline,
        [withoutSupersedes],
      ),
      throwsFormatException,
    );

    final withSupersedes = PlacementVerificationRecord(
      id: withoutSupersedes.id,
      siteId: siteId,
      latitude: withoutSupersedes.latitude,
      longitude: withoutSupersedes.longitude,
      quality: withoutSupersedes.quality,
      confidence: withoutSupersedes.confidence,
      method: withoutSupersedes.method,
      verifiedAt: withoutSupersedes.verifiedAt,
      nearbyRankingEligible: false,
      navigationEligible: false,
      supersedesPlacementId: existing.id,
      evidence: withoutSupersedes.evidence,
    );

    final result = const PlacementVerificationEngine().apply(
      baseline,
      [withSupersedes],
    );
    expect(result.snapshot.placementsForSite(siteId), hasLength(1));
    expect(
      result.snapshot.placementsForSite(siteId).single.quality,
      PlacementQuality.propertyReference,
    );
  });

  test('pilot records authoritative coordinate but rejects Site association', () async {
    final raw = await rootBundle.loadString(
      'data/site_enrichment/2026-11-19_placement_enrichment_pilot.json',
    );
    final document = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final reviews = document['reviews'] as List<dynamic>;

    expect(document['outreach_performed'], isFalse);
    expect(reviews, hasLength(1));

    final review = Map<String, dynamic>.from(reviews.single as Map);
    expect(review['outcome'], 'rejected_site_identity_ambiguous');
    expect(review['accepted_verification_id'], isNull);

    final wgs84 =
        Map<String, dynamic>.from(review['derived_wgs84'] as Map);
    expect((wgs84['latitude'] as num).toDouble(), closeTo(-12.239774, 1e-6));
    expect((wgs84['longitude'] as num).toDouble(), closeTo(-76.952451, 1e-6));
  });
}
