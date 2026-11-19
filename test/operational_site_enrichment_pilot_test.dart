import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/sites/data/operational_site_verification_repository.dart';
import 'package:nexo_industrial/features/sites/domain/site.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('production pilot promotes exactly four evidence-backed operational sites', () async {
    final result =
        await const AssetOperationalSiteVerificationRepository().loadSnapshot();

    expect(result.verifications, hasLength(4));
    expect(result.claims, hasLength(4));
    expect(
      result.snapshot.sites.where((site) => site.isOperationallyConfirmed),
      hasLength(4),
    );
    expect(
      result.snapshot.gaps
          .where((gap) => gap.predicate == 'organization.operational_site'),
      hasLength(1903),
    );
  });

  test('accepted pilot sites preserve the intended functions', () async {
    final result =
        await const AssetOperationalSiteVerificationRepository().loadSnapshot();

    final byRuc = {
      for (final site in result.snapshot.sites)
        if (site.isOperationallyConfirmed) site.organizationRuc: site,
    };

    expect(byRuc.keys, {
      '20100003351',
      '20262254268',
      '20114915026',
      '20100307902',
    });
    expect(byRuc['20100003351']!.function, SiteFunction.shipyard);
    expect(byRuc['20262254268']!.function, SiteFunction.terminal);
    expect(byRuc['20114915026']!.function, SiteFunction.mine);
    expect(byRuc['20100307902']!.function, SiteFunction.office);
  });

  test('rejected pilot accounts remain operationally unknown', () async {
    final result =
        await const AssetOperationalSiteVerificationRepository().loadSnapshot();

    for (final ruc in ['20501523837', '20329921531']) {
      final sites = result.snapshot.sites
          .where((site) => site.organizationRuc == ruc)
          .toList(growable: false);
      expect(sites, hasLength(1));
      expect(sites.single.operationalStatus, SiteOperationalStatus.unknown);
      expect(
        result.snapshot.gaps.any(
          (gap) =>
              gap.predicate == 'organization.operational_site' &&
              gap.subject.id == ruc,
        ),
        isTrue,
      );
    }
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

    expect(acceptedIds, verificationIds);
  });
}
