import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/knowledge/data/asset_knowledge_repository.dart';
import 'package:nexo_industrial/features/knowledge/domain/knowledge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late KnowledgeSnapshot snapshot;

  setUpAll(() async {
    snapshot = await const AssetKnowledgeRepository().loadSnapshot();
  });

  test('projects one evidenced geographic claim for every canonical account', () {
    final locations = snapshot
        .claimsWhere('organization.location')
        .toList(growable: false);

    expect(locations, hasLength(1907));
    expect(
      locations.map((claim) => claim.subject.id).toSet(),
      hasLength(1907),
    );
    expect(locations.every((claim) => claim.hasEvidence), isTrue);
    expect(
      locations.every(
        (claim) => claim.origin == KnowledgeOrigin.authoritative,
      ),
      isTrue,
    );
  });

  test('models direct-contact unknowns instead of false values', () {
    final directContactRucs = <String>{
      ...snapshot
          .claimsWhere('organization.contact.phone')
          .map((claim) => claim.subject.id),
      ...snapshot
          .claimsWhere('organization.contact.email')
          .map((claim) => claim.subject.id),
    };
    final directContactGaps = snapshot
        .gapsWhere('organization.direct_contact')
        .toList(growable: false);

    expect(directContactRucs, hasLength(299));
    expect(directContactGaps, hasLength(1608));
    expect(
      directContactGaps
          .map((gap) => gap.subject.id)
          .toSet()
          .intersection(directContactRucs),
      isEmpty,
    );
    expect(
      directContactGaps.every(
        (gap) => gap.reason == KnowledgeGapReason.unknown,
      ),
      isTrue,
    );
  });

  test('preserves 33 professional role claims across 21 organizations', () {
    final roles = snapshot
        .claimsWhere('person.role_at_organization')
        .toList(growable: false);

    expect(roles, hasLength(33));
    expect(
      roles.map((claim) => claim.metadata['organization_ruc']).toSet(),
      hasLength(21),
    );
    expect(roles.every((claim) => claim.hasEvidence), isTrue);
  });

  test('keeps epistemic origin, time and confidence as separate dimensions', () {
    final pieri = snapshot
        .claimsWhere('person.role_at_organization')
        .singleWhere(
          (claim) => claim.metadata['display_name'] == 'Pieri Maguiña',
        );

    expect(pieri.origin, KnowledgeOrigin.declared);
    expect(pieri.temporalMode, KnowledgeTemporalMode.current);
    expect(pieri.confidence, KnowledgeConfidence.high);
    expect(pieri.asOf, DateTime(2026, 11, 11));

    final ralph = snapshot
        .claimsWhere('person.role_at_organization')
        .singleWhere(
          (claim) =>
              claim.metadata['display_name'] ==
              'Ralph Alosilla-Velazco Vera',
        );

    expect(ralph.temporalMode, KnowledgeTemporalMode.historical);
    expect(ralph.origin, KnowledgeOrigin.declared);
  });

  test('never creates a claim without resolvable evidence', () {
    expect(snapshot.claims.every((claim) => claim.evidenceIds.isNotEmpty), isTrue);

    final evidenceIds = snapshot.evidence.map((evidence) => evidence.id).toSet();
    expect(evidenceIds, hasLength(snapshot.evidence.length));

    for (final claim in snapshot.claims) {
      for (final evidenceId in claim.evidenceIds) {
        expect(
          evidenceIds.contains(evidenceId),
          isTrue,
          reason: '${claim.id} references $evidenceId',
        );
      }
    }
  });

  test('public URL evidence remains explicit and HTTPS', () {
    final publicEvidence = snapshot.evidence
        .where((item) => item.sourceType == EvidenceSourceType.url)
        .toList(growable: false);

    expect(publicEvidence, isNotEmpty);
    expect(
      publicEvidence.every((item) {
        final uri = Uri.tryParse(item.locator);
        return uri != null &&
            uri.scheme == 'https' &&
            uri.host.isNotEmpty;
      }),
      isTrue,
    );
  });
}
