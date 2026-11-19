import '../../knowledge/domain/knowledge.dart';
import 'site.dart';

enum SiteIdentityRelation {
  sameSite,
  adjacentSite,
  distinctSite,
  unknown,
}

enum SiteIdentityReconciliationMethod {
  officialCrossReference,
  officialSource,
  fieldObservation,
  manualReview,
}

class SiteIdentityReconciliationRecord {
  const SiteIdentityReconciliationRecord({
    required this.id,
    required this.organizationRuc,
    required this.leftSiteId,
    required this.rightSiteId,
    required this.relation,
    required this.method,
    required this.confidence,
    required this.reviewedAt,
    required this.evidence,
    this.canonicalSiteId,
    this.rationale,
  });

  final String id;
  final String organizationRuc;
  final String leftSiteId;
  final String rightSiteId;
  final SiteIdentityRelation relation;
  final SiteIdentityReconciliationMethod method;
  final KnowledgeConfidence confidence;
  final DateTime reviewedAt;
  final List<EvidenceRef> evidence;
  final String? canonicalSiteId;
  final String? rationale;
}

class SiteAlias {
  const SiteAlias({
    required this.aliasSiteId,
    required this.canonicalSiteId,
    required this.aliasLabel,
    required this.reconciliationId,
  });

  final String aliasSiteId;
  final String canonicalSiteId;
  final String aliasLabel;
  final String reconciliationId;
}

class SiteIdentityReconciliationResult {
  SiteIdentityReconciliationResult({
    required this.snapshot,
    required List<SiteIdentityReconciliationRecord> reconciliations,
    required List<SiteAlias> aliases,
    required List<KnowledgeClaim> claims,
    required List<EvidenceRef> evidence,
  })  : reconciliations = List.unmodifiable(reconciliations),
        aliases = List.unmodifiable(aliases),
        claims = List.unmodifiable(claims),
        evidence = List.unmodifiable(evidence);

  final SiteSnapshot snapshot;
  final List<SiteIdentityReconciliationRecord> reconciliations;
  final List<SiteAlias> aliases;
  final List<KnowledgeClaim> claims;
  final List<EvidenceRef> evidence;

  String canonicalSiteIdFor(String siteId) {
    for (final alias in aliases) {
      if (alias.aliasSiteId == siteId) return alias.canonicalSiteId;
    }
    return siteId;
  }
}
