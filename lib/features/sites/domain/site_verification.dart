import '../../knowledge/domain/knowledge.dart';
import 'site.dart';

enum OperationalSiteDecision { operational, notOperational }

enum OperationalSiteVerificationMethod {
  publicSource,
  officialSource,
  fieldObservation,
  manualReview,
}

class OperationalSiteVerification {
  const OperationalSiteVerification({
    required this.id,
    required this.siteId,
    required this.organizationRuc,
    required this.decision,
    required this.function,
    required this.method,
    required this.verifiedAt,
    required this.evidence,
    this.validFrom,
    this.validUntil,
    this.reviewer,
    this.notes,
  });

  final String id;
  final String siteId;
  final String organizationRuc;
  final OperationalSiteDecision decision;
  final SiteFunction function;
  final OperationalSiteVerificationMethod method;
  final DateTime verifiedAt;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final String? reviewer;
  final String? notes;
  final List<EvidenceRef> evidence;

  SiteOperationalStatus get operationalStatus => switch (decision) {
        OperationalSiteDecision.operational =>
          SiteOperationalStatus.confirmedOperational,
        OperationalSiteDecision.notOperational =>
          SiteOperationalStatus.confirmedNotOperational,
      };

  KnowledgeOrigin get claimOrigin => switch (method) {
        OperationalSiteVerificationMethod.fieldObservation =>
          KnowledgeOrigin.observed,
        OperationalSiteVerificationMethod.publicSource ||
        OperationalSiteVerificationMethod.officialSource =>
          KnowledgeOrigin.declared,
        OperationalSiteVerificationMethod.manualReview =>
          KnowledgeOrigin.derived,
      };
}

class SiteVerificationResult {
  SiteVerificationResult({
    required this.snapshot,
    required List<OperationalSiteVerification> verifications,
    required List<KnowledgeClaim> claims,
    required List<EvidenceRef> evidence,
  })  : verifications = List.unmodifiable(verifications),
        claims = List.unmodifiable(claims),
        evidence = List.unmodifiable(evidence);

  final SiteSnapshot snapshot;
  final List<OperationalSiteVerification> verifications;
  final List<KnowledgeClaim> claims;
  final List<EvidenceRef> evidence;
}
