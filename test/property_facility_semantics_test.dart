import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_industrial/features/sites/data/property_facility_repository.dart';
import 'package:nexo_industrial/features/sites/data/site_identity_reconciliation_repository.dart';
import 'package:nexo_industrial/features/sites/domain/property_facility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const canonicalSite = 'site:20501523837:reference-1';
  const property = 'property:20501523837:mz-b-lote-1';
  const facility = 'facility:20501523837:mz-b-lote-1:warehouse';
  const asset = 'asset:20501523837:mz-b-lote-1:groundwater-well';

  test('CONTRACT 027 preserves the active Site snapshot', () async {
    final sites =
        await const AssetSiteIdentityReconciliationRepository().loadSnapshot();
    final semantics = await const AssetPropertyFacilityRepository().loadSnapshot();

    expect(sites.snapshot.sites, hasLength(1907));
    expect(sites.snapshot.placements, hasLength(1907));
    expect(sites.snapshot.siteById(canonicalSite), isNotNull);

    expect(semantics.properties, hasLength(1));
    expect(semantics.facilities, hasLength(1));
    expect(semantics.assets, hasLength(1));
    expect(semantics.placements, hasLength(1));
    expect(semantics.relationships, hasLength(1));
  });

  test('Explomin Lote 1 is a distinct Property, not a second Site', () async {
    final sites =
        await const AssetSiteIdentityReconciliationRepository().loadSnapshot();
    final semantics = await const AssetPropertyFacilityRepository().loadSnapshot();

    final relationship = semantics.relationships.single;
    expect(relationship.propertyId, property);
    expect(relationship.siteId, canonicalSite);
    expect(relationship.relation, PropertyRelation.distinctProperty);
    expect(relationship.operationallyRelated, isTrue);

    expect(
      sites.snapshot.sitesForOrganization('20501523837'),
      hasLength(1),
    );
  });

  test('warehouse belongs to Property and well belongs to warehouse', () async {
    final semantics = await const AssetPropertyFacilityRepository().loadSnapshot();

    expect(semantics.facilities.single.id, facility);
    expect(semantics.facilities.single.propertyId, property);
    expect(
      semantics.facilities.single.type,
      OperationalFacilityType.warehouse,
    );

    expect(semantics.assets.single.id, asset);
    expect(semantics.assets.single.facilityId, facility);
  });

  test('ANA coordinate belongs to Asset and never to canonical Site', () async {
    final semantics = await const AssetPropertyFacilityRepository().loadSnapshot();

    final placement = semantics.placements.single;
    expect(placement.entityType, SpatialEntityType.asset);
    expect(placement.entityId, asset);
    expect(placement.entityId, isNot(canonicalSite));
    expect(placement.hasValidCoordinates, isTrue);
    expect(
      placement.sourceCoordinateReferenceSystem,
      contains('UTM WGS84 Zone 18S'),
    );
  });

  test('semantic claims preserve Property and Facility claims', () async {
    final semantics = await const AssetPropertyFacilityRepository().loadSnapshot();

    expect(
      semantics.claims.any((claim) => claim.predicate == 'property.site_relation'),
      isTrue,
    );
    expect(
      semantics.claims.any((claim) => claim.predicate == 'facility.exists'),
      isTrue,
    );
  });
}
