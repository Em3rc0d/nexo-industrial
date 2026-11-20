import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../domain/knowledge.dart';

class AssetKnowledgeRepository {
  const AssetKnowledgeRepository({
    this.companyAssetPath = 'assets/data/companies.production.json',
    this.commercialOverlayPath =
        'assets/data/companies.commercial.overlay.json.gz',
    this.geolocationOverlayPath =
        'assets/data/companies.geolocation.overlay.json',
    this.peopleAssetPath =
        'data/people_enrichment/2026-11-11_mining_people.json',
    this.contactPatchAssetPath = 'assets/data/companies.contact.patch.json',
  });

  final String companyAssetPath;
  final String commercialOverlayPath;
  final String geolocationOverlayPath;
  final String peopleAssetPath;
  final String contactPatchAssetPath;

  Future<KnowledgeSnapshot> loadSnapshot() async {
    final companyRaw = await rootBundle.loadString(companyAssetPath);
    final commercialBytes = await rootBundle.load(commercialOverlayPath);
    final geolocationRaw = await rootBundle.loadString(geolocationOverlayPath);
    final peopleRaw = await rootBundle.loadString(peopleAssetPath);
    final contactPatchRaw = await rootBundle.loadString(contactPatchAssetPath);

    final companies = (jsonDecode(companyRaw) as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);

    final commercialRaw = utf8.decode(
      gzip.decode(
        commercialBytes.buffer.asUint8List(
          commercialBytes.offsetInBytes,
          commercialBytes.lengthInBytes,
        ),
      ),
    );
    final commercial = (jsonDecode(commercialRaw) as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);

    final geography = (jsonDecode(geolocationRaw) as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);

    final peopleDocument =
        Map<String, dynamic>.from(jsonDecode(peopleRaw) as Map);
    final people = (peopleDocument['records'] as List<dynamic>? ?? const [])
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);

    final patchDocument =
        Map<String, dynamic>.from(jsonDecode(contactPatchRaw) as Map);
    final patches = (patchDocument['records'] as List<dynamic>? ?? const [])
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);

    final canonicalRucs = <String>{
      for (final company in companies) company['ruc'].toString(),
    };
    if (canonicalRucs.length != companies.length) {
      throw const FormatException('Canonical company RUCs must be unique.');
    }

    final claims = <KnowledgeClaim>[];
    final evidenceById = <String, EvidenceRef>{};
    final gaps = <KnowledgeGap>[];

    void addEvidence(EvidenceRef evidence) {
      final existing = evidenceById[evidence.id];
      if (existing != null &&
          (existing.locator != evidence.locator ||
              existing.sourceType != evidence.sourceType)) {
        throw FormatException('Conflicting evidence id: ${evidence.id}');
      }
      evidenceById[evidence.id] = existing ?? evidence;
    }

    for (final row in geography) {
      final ruc = row['ruc'].toString();
      if (!canonicalRucs.contains(ruc)) {
        throw FormatException('Unknown geographic RUC: $ruc');
      }

      final source = _nonEmpty(row['source']) ?? geolocationOverlayPath;
      final evidenceId = 'evidence:geography:$ruc';
      final asOf = _parseDate(
        row['geocoded_at'] ?? row['geocoding_checked_at'],
      );

      addEvidence(
        EvidenceRef(
          id: evidenceId,
          sourceType: _sourceType(source),
          locator: source,
          reviewedAt: asOf,
          summary: _nonEmpty(row['validation']) ??
              _nonEmpty(row['geocoding_status']) ??
              'Audited geographic overlay.',
          metadata: {
            'asset': geolocationOverlayPath,
            ..._optionalMetadata('location_quality', row['location_quality']),
          },
        ),
      );

      claims.add(
        KnowledgeClaim(
          id: 'claim:organization:$ruc:location',
          subject: KnowledgeSubjectRef(
            type: KnowledgeSubjectType.organization,
            id: ruc,
          ),
          predicate: 'organization.location',
          value: Map<String, Object?>.unmodifiable({
            'latitude': row['latitude'],
            'longitude': row['longitude'],
            'location_quality':
                row['location_quality'] ?? row['precision'] ?? 'unknown',
            'district': row['district'],
            'province': row['province'],
            'department': row['department'],
            'map_display_eligible': row['map_display_eligible'] ?? false,
            'nearby_ranking_eligible':
                row['nearby_ranking_eligible'] ?? false,
            'navigation_eligible': row['navigation_eligible'] ?? false,
          }),
          origin: KnowledgeOrigin.authoritative,
          temporalMode: KnowledgeTemporalMode.current,
          confidence: _confidence(row['location_confidence']),
          asOf: asOf,
          evidenceIds: [evidenceId],
          metadata: const {
            'knowledge_family': 'geography',
          },
        ),
      );
    }

    final commercialByRuc = <String, Map<String, dynamic>>{
      for (final row in commercial) row['ruc'].toString(): row,
    };
    final patchByRuc = <String, Map<String, dynamic>>{
      for (final row in patches) row['ruc'].toString(): row,
    };

    if (commercialByRuc.length != canonicalRucs.length ||
        !canonicalRucs.every(commercialByRuc.containsKey)) {
      throw const FormatException(
        'Commercial overlay must cover every canonical RUC exactly once.',
      );
    }

    final directContactRucs = <String>{};

    for (final ruc in canonicalRucs) {
      final commercialRow = commercialByRuc[ruc]!;
      final baseContact = Map<String, dynamic>.from(
        commercialRow['contact'] as Map? ?? const {},
      );
      final patch = patchByRuc[ruc];

      var phone = _nonEmpty(baseContact['phone']);
      var email = _nonEmpty(baseContact['email']);
      var phoneEvidenceIds = <String>[];
      var emailEvidenceIds = <String>[];

      if (phone != null || email != null) {
        final source = _nonEmpty(commercialRow['contact_source']) ??
            _nonEmpty(baseContact['source']) ??
            commercialOverlayPath;
        final sourceDate = _parseDate(commercialRow['source_date']);
        final evidenceId = 'evidence:contact-base:$ruc';

        addEvidence(
          EvidenceRef(
            id: evidenceId,
            sourceType: _sourceType(source),
            locator: source,
            reviewedAt: sourceDate,
            summary: 'Published contact information from the commercial overlay.',
            metadata: {
              'asset': commercialOverlayPath,
            },
          ),
        );

        if (phone != null) phoneEvidenceIds = [evidenceId];
        if (email != null) emailEvidenceIds = [evidenceId];
      }

      if (patch != null) {
        final source = _nonEmpty(patch['source_url']);
        if (source == null || !_isHttps(source)) {
          throw FormatException('Invalid contact patch source for RUC: $ruc');
        }

        final evidenceId = 'evidence:contact-patch:$ruc';
        final reviewedAt = _parseDate(patch['reviewed_on']);
        addEvidence(
          EvidenceRef(
            id: evidenceId,
            sourceType: EvidenceSourceType.url,
            locator: source,
            reviewedAt: reviewedAt,
            summary: _nonEmpty(patch['notes']) ??
                'Published company channel; no outreach performed.',
            metadata: {
              'asset': contactPatchAssetPath,
              ..._optionalMetadata('channel_purpose', patch['channel_purpose']),
              ..._optionalMetadata('status', patch['status']),
            },
          ),
        );

        final patchPhone = _nonEmpty(patch['phone']);
        final patchEmail = _nonEmpty(patch['email']);

        if (phone == null && patchPhone != null) {
          phone = patchPhone;
          phoneEvidenceIds = [evidenceId];
        }
        if (email == null && patchEmail != null) {
          email = patchEmail;
          emailEvidenceIds = [evidenceId];
        }
      }

      final sourceDate = _parseDate(commercialRow['source_date']);

      if (phone != null) {
        directContactRucs.add(ruc);
        claims.add(
          KnowledgeClaim(
            id: 'claim:organization:$ruc:contact:phone',
            subject: KnowledgeSubjectRef(
              type: KnowledgeSubjectType.organization,
              id: ruc,
            ),
            predicate: 'organization.contact.phone',
            value: phone,
            origin: KnowledgeOrigin.observed,
            temporalMode: KnowledgeTemporalMode.current,
            confidence: _confidence(commercialRow['confidence']),
            asOf: _latestEvidenceDate(
              phoneEvidenceIds,
              evidenceById,
            ) ?? sourceDate,
            evidenceIds: phoneEvidenceIds,
            metadata: const {
              'knowledge_family': 'contact',
            },
          ),
        );
      }

      if (email != null) {
        directContactRucs.add(ruc);
        claims.add(
          KnowledgeClaim(
            id: 'claim:organization:$ruc:contact:email',
            subject: KnowledgeSubjectRef(
              type: KnowledgeSubjectType.organization,
              id: ruc,
            ),
            predicate: 'organization.contact.email',
            value: email,
            origin: KnowledgeOrigin.observed,
            temporalMode: KnowledgeTemporalMode.current,
            confidence: _confidence(commercialRow['confidence']),
            asOf: _latestEvidenceDate(
              emailEvidenceIds,
              evidenceById,
            ) ?? sourceDate,
            evidenceIds: emailEvidenceIds,
            metadata: const {
              'knowledge_family': 'contact',
            },
          ),
        );
      }
    }

    final gapAsOf = _parseDate(
      patchDocument['as_of'] ?? patchDocument['generated_at'],
    );
    for (final ruc in canonicalRucs.difference(directContactRucs)) {
      gaps.add(
        KnowledgeGap(
          id: 'gap:organization:$ruc:direct-contact',
          subject: KnowledgeSubjectRef(
            type: KnowledgeSubjectType.organization,
            id: ruc,
          ),
          predicate: 'organization.direct_contact',
          reason: KnowledgeGapReason.unknown,
          identifiedAt: gapAsOf,
          metadata: const {
            'meaning': 'No published phone or email is currently loaded.',
          },
        ),
      );
    }

    for (final row in people) {
      final ruc = row['ruc'].toString();
      if (!canonicalRucs.contains(ruc)) {
        throw FormatException('Unknown professional RUC: $ruc');
      }

      final name = _nonEmpty(row['name']);
      final role = _nonEmpty(row['role']);
      if (name == null || role == null) {
        throw FormatException('Professional identity requires name and role: $ruc');
      }

      final personId = 'person:$ruc:${_slug(name)}';
      final reviewedAt = _parseDate(row['reviewed_on']);
      final evidenceIds = <String>[];

      for (final field in ['evidence_url', 'evidence_url_secondary']) {
        final locator = _nonEmpty(row[field]);
        if (locator == null) continue;
        final suffix = field == 'evidence_url' ? 'primary' : 'secondary';
        final evidenceId = 'evidence:person:$ruc:${_slug(name)}:$suffix';

        addEvidence(
          EvidenceRef(
            id: evidenceId,
            sourceType: _sourceType(locator),
            locator: locator,
            reviewedAt: reviewedAt,
            summary: _nonEmpty(row['evidence_summary']),
            metadata: {
              'asset': peopleAssetPath,
              ..._optionalMetadata('status', row['status']),
            },
          ),
        );
        evidenceIds.add(evidenceId);
      }

      if (evidenceIds.isEmpty) {
        final evidenceId = 'evidence:person:$ruc:${_slug(name)}:dataset';
        addEvidence(
          EvidenceRef(
            id: evidenceId,
            sourceType: EvidenceSourceType.dataset,
            locator: peopleAssetPath,
            reviewedAt: reviewedAt,
            summary: _nonEmpty(row['evidence_summary']),
          ),
        );
        evidenceIds.add(evidenceId);
      }

      final status = _nonEmpty(row['status']) ?? '';
      final historical = status == 'historical_role_needs_reconfirmation';

      claims.add(
        KnowledgeClaim(
          id: 'claim:$personId:role-at:$ruc',
          subject: KnowledgeSubjectRef(
            type: KnowledgeSubjectType.person,
            id: personId,
          ),
          predicate: 'person.role_at_organization',
          value: role,
          origin: KnowledgeOrigin.declared,
          temporalMode: historical
              ? KnowledgeTemporalMode.historical
              : KnowledgeTemporalMode.current,
          confidence: _confidence(row['confidence']),
          asOf: reviewedAt,
          evidenceIds: evidenceIds,
          metadata: {
            'display_name': name,
            'organization_ruc': ruc,
            ..._optionalMetadata('department', row['department']),
            ..._optionalMetadata('source_status', status),
          },
        ),
      );
    }

    final claimIds = <String>{};
    for (final claim in claims) {
      if (!claimIds.add(claim.id)) {
        throw FormatException('Duplicate knowledge claim id: ${claim.id}');
      }
      if (!claim.hasEvidence) {
        throw FormatException('Knowledge claim without evidence: ${claim.id}');
      }
      for (final evidenceId in claim.evidenceIds) {
        if (!evidenceById.containsKey(evidenceId)) {
          throw FormatException(
            'Claim references missing evidence: ${claim.id} -> $evidenceId',
          );
        }
      }
    }

    return KnowledgeSnapshot(
      claims: claims,
      evidence: evidenceById.values.toList(growable: false),
      gaps: gaps,
    );
  }
}

String? _nonEmpty(Object? value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

DateTime? _parseDate(Object? value) {
  final text = _nonEmpty(value);
  return text == null ? null : DateTime.tryParse(text);
}

EvidenceSourceType _sourceType(String locator) =>
    _isHttps(locator) ? EvidenceSourceType.url : EvidenceSourceType.dataset;

bool _isHttps(String value) {
  final uri = Uri.tryParse(value);
  return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
}

KnowledgeConfidence _confidence(Object? value) {
  return switch (_nonEmpty(value)?.toLowerCase()) {
    'high' || 'confirmed' => KnowledgeConfidence.high,
    'medium' => KnowledgeConfidence.medium,
    'low' => KnowledgeConfidence.low,
    'very_low' => KnowledgeConfidence.veryLow,
    _ => KnowledgeConfidence.unknown,
  };
}

DateTime? _latestEvidenceDate(
  Iterable<String> evidenceIds,
  Map<String, EvidenceRef> evidenceById,
) {
  DateTime? latest;
  for (final id in evidenceIds) {
    final evidence = evidenceById[id];
    final candidate = evidence?.reviewedAt ?? evidence?.observedAt;
    if (candidate != null && (latest == null || candidate.isAfter(latest))) {
      latest = candidate;
    }
  }
  return latest;
}

String _slug(String value) {
  var result = value.toLowerCase();
  const replacements = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  for (final entry in replacements.entries) {
    result = result.replaceAll(entry.key, entry.value);
  }
  return result
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}


Map<String, String> _optionalMetadata(String key, Object? value) {
  final text = _nonEmpty(value);
  return text == null ? const {} : {key: text};
}
