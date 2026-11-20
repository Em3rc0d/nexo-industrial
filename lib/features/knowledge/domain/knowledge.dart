enum KnowledgeSubjectType {\n  organization,\n  person,\n  site,\n  property,\n  operationalFacility,\n  asset,\n}

enum KnowledgeOrigin {
  authoritative,
  observed,
  declared,
  derived,
  hypothesis,
}

enum KnowledgeTemporalMode { current, historical, expected, simulated }

enum KnowledgeConfidence { high, medium, low, veryLow, unknown }

enum EvidenceSourceType { dataset, url, userActivity, systemDerived }

enum KnowledgeGapReason {
  unknown,
  notFound,
  unverified,
  conflicting,
  stale,
}

class KnowledgeSubjectRef {
  const KnowledgeSubjectRef({
    required this.type,
    required this.id,
  });

  final KnowledgeSubjectType type;
  final String id;
}

class EvidenceRef {
  const EvidenceRef({
    required this.id,
    required this.sourceType,
    required this.locator,
    this.reviewedAt,
    this.observedAt,
    this.summary,
    this.metadata = const {},
  });

  final String id;
  final EvidenceSourceType sourceType;
  final String locator;
  final DateTime? reviewedAt;
  final DateTime? observedAt;
  final String? summary;
  final Map<String, String> metadata;
}

class KnowledgeClaim {
  const KnowledgeClaim({
    required this.id,
    required this.subject,
    required this.predicate,
    required this.value,
    required this.origin,
    required this.temporalMode,
    required this.confidence,
    required this.evidenceIds,
    this.asOf,
    this.validFrom,
    this.validUntil,
    this.metadata = const {},
  });

  final String id;
  final KnowledgeSubjectRef subject;
  final String predicate;
  final Object? value;

  /// Epistemic origin: how the statement entered the knowledge model.
  final KnowledgeOrigin origin;

  /// Temporal mode is intentionally independent from epistemic origin.
  final KnowledgeTemporalMode temporalMode;
  final KnowledgeConfidence confidence;

  /// Date the statement is known to describe or have been reviewed at.
  /// Null means freshness is unknown; null must never be interpreted as fresh.
  final DateTime? asOf;

  final DateTime? validFrom;
  final DateTime? validUntil;
  final List<String> evidenceIds;
  final Map<String, String> metadata;

  bool get hasEvidence => evidenceIds.isNotEmpty;
  bool get freshnessKnown => asOf != null;
}

class KnowledgeGap {
  const KnowledgeGap({
    required this.id,
    required this.subject,
    required this.predicate,
    required this.reason,
    this.identifiedAt,
    this.metadata = const {},
  });

  final String id;
  final KnowledgeSubjectRef subject;
  final String predicate;
  final KnowledgeGapReason reason;
  final DateTime? identifiedAt;
  final Map<String, String> metadata;
}

class KnowledgeSnapshot {
  KnowledgeSnapshot({
    required List<KnowledgeClaim> claims,
    required List<EvidenceRef> evidence,
    required List<KnowledgeGap> gaps,
  })  : claims = List.unmodifiable(claims),
        evidence = List.unmodifiable(evidence),
        gaps = List.unmodifiable(gaps);

  final List<KnowledgeClaim> claims;
  final List<EvidenceRef> evidence;
  final List<KnowledgeGap> gaps;

  Iterable<KnowledgeClaim> claimsWhere(String predicate) =>
      claims.where((claim) => claim.predicate == predicate);

  Iterable<KnowledgeGap> gapsWhere(String predicate) =>
      gaps.where((gap) => gap.predicate == predicate);

  EvidenceRef? evidenceById(String id) {
    for (final item in evidence) {
      if (item.id == id) return item;
    }
    return null;
  }
}
