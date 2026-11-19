import '../../knowledge/domain/knowledge.dart';
import 'site.dart';

enum SiteDiscoveryMethod {
  officialSource,
  publicSource,
  fieldObservation,
  manualReview,
}

class SiteDiscoveryRecord {
  const SiteDiscoveryRecord({
    required this.id,
    required this.siteId,
    required this.organizationRuc,
    required this.displayLabel,
    required this.function,
    required this.method,
    required this.discoveredAt,
    required this.evidence,
  });

  final String id;
  final String siteId;
  final String organizationRuc;
  final String displayLabel;
  final SiteFunction function;
  final SiteDiscoveryMethod method;
  final DateTime discoveredAt;
  final List<EvidenceRef> evidence;
}

class SiteDiscoveryResult {
  SiteDiscoveryResult({
    required this.snapshot,
    required List<SiteDiscoveryRecord> discoveries,
    required List<KnowledgeClaim> claims,
    required List<EvidenceRef> evidence,
  })  : discoveries = List.unmodifiable(discoveries),
        claims = List.unmodifiable(claims),
        evidence = List.unmodifiable(evidence);

  final SiteSnapshot snapshot;
  final List<SiteDiscoveryRecord> discoveries;
  final List<KnowledgeClaim> claims;
  final List<EvidenceRef> evidence;
}
