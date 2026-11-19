import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/sites/data/operational_site_verification_repository.dart';
import 'package:nexo_industrial/features/sites/domain/site.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('historical pilot accepted verifications remain present', () async {
    final result =
        await const AssetOperationalSiteVerificationRepository().loadSnapshot();

    final ids = result.verifications.map((item) => item.id).toSet();
    expect(
      ids,
      containsAll({
        'verification:20100003351:sima-callao:20261119',
        'verification:20262254268:zeta-gas-oquendo:20261119',
        'verification:20114915026:antapaccay-tintaya:20261119',
        'verification:20100307902:resemin-ate-office:20261119',
      }),
    );
  });

  test('accepted pilot sites preserve the intended functions', () async {
    final result =
        await const AssetOperationalSiteVerificationRepository().loadSnapshot();

    final byRuc = {
      for (final site in result.snapshot.sites)
        if (site.isOperationallyConfirmed) site.organizationRuc: site,
    };

    expect(byRuc['20100003351']!.function, SiteFunction.shipyard);
    expect(byRuc['20262254268']!.function, SiteFunction.terminal);
    expect(byRuc['20114915026']!.function, SiteFunction.mine);
    expect(byRuc['20100307902']!.function, SiteFunction.office);
  });

  test('historical rejections remain truthful after later reconciliation', () async {
    final raw = await rootBundle.loadString(
      'data/site_enrichment/2026-11-19_operational_site_pilot.json',
    );
    final document = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final reviews = (document['reviews'] as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);

    final explomin = reviews.singleWhere(
      (row) => row['ruc'] == '20501523837',
    );
    expect(explomin['outcome'], 'rejected_reference_mismatch');

    final result =
        await const AssetOperationalSiteVerificationRepository().loadSnapshot();
    final canonical = result.snapshot.siteById(
      'site:20501523837:reference-1',
    )!;
    expect(
      canonical.operationalStatus,
      SiteOperationalStatus.confirmedOperational,
    );

    final masterSites = result.snapshot.sites
        .where((site) => site.organizationRuc == '20329921531')
        .toList(growable: false);
    expect(masterSites, hasLength(1));
    expect(masterSites.single.operationalStatus, SiteOperationalStatus.unknown);
  });

  test('pilot audit records six reviews, four accepted and no outreach', () async {
    final raw = await rootBundle.loadString(
      'data/site_enrichment/2026-11-19_operational_site_pilot.json',
    );
    final document = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final reviews = (document['reviews'] as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);

    expect(document['outreach_performed'], isFalse);
    expect(reviews, hasLength(6));
    expect(
      reviews.where((row) => row['outcome'] == 'accepted'),
      hasLength(4),
    );
    expect(
      reviews.where((row) => row['outcome'] != 'accepted'),
      hasLength(2),
    );
  });

  test('every accepted review maps one-to-one to a production verification', () async {
    final raw = await rootBundle.loadString(
      'data/site_enrichment/2026-11-19_operational_site_pilot.json',
    );
    final document = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final reviews = (document['reviews'] as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);

    final result =
        await const AssetOperationalSiteVerificationRepository().loadSnapshot();
    final verificationIds =
        result.verifications.map((item) => item.id).toSet();

    final acceptedIds = reviews
        .where((row) => row['outcome'] == 'accepted')
        .map((row) => row['verification_id'].toString())
        .toSet();

    expect(verificationIds, containsAll(acceptedIds));
  });
}
