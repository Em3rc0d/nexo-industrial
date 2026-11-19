import '../../knowledge/domain/knowledge.dart';
import 'site.dart';

enum PlacementVerificationMethod {
  officialCoordinates,
  fieldObservation,
  publicGeocoder,
  manualReview,
}

class PlacementVerificationRecord {
  const PlacementVerificationRecord({
    required this.id,
    required this.siteId,
    required this.latitude,
    required this.longitude,
    required this.quality,
    required this.confidence,
    required this.method,
    required this.verifiedAt,
    required this.nearbyRankingEligible,
    required this.navigationEligible,
    required this.evidence,
    this.address,
    this.district,
    this.province,
    this.department,
    this.supersedesPlacementId,
    this.sourceCoordinateReferenceSystem,
    this.notes,
  });

  final String id;
  final String siteId;
  final double latitude;
  final double longitude;
  final PlacementQuality quality;
  final KnowledgeConfidence confidence;
  final PlacementVerificationMethod method;
  final DateTime verifiedAt;
  final bool nearbyRankingEligible;
  final bool navigationEligible;
  final List<EvidenceRef> evidence;

  final String? address;
  final String? district;
  final String? province;
  final String? department;
  final String? supersedesPlacementId;
  final String? sourceCoordinateReferenceSystem;
  final String? notes;
}

class PlacementVerificationResult {
  PlacementVerificationResult({
    required this.snapshot,
    required List<PlacementVerificationRecord> verifications,
    required List<KnowledgeClaim> claims,
    required List<EvidenceRef> evidence,
  })  : verifications = List.unmodifiable(verifications),
        claims = List.unmodifiable(claims),
        evidence = List.unmodifiable(evidence);

  final SiteSnapshot snapshot;
  final List<PlacementVerificationRecord> verifications;
  final List<KnowledgeClaim> claims;
  final List<EvidenceRef> evidence;
}
