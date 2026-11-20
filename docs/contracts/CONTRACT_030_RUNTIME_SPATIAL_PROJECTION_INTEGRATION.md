# CONTRACT 030 — Runtime Spatial Projection Integration

## Objective

Move spatial consumption in the running application away from
`Company.latitude/longitude` and related Company-level geography flags.

CONTRACT 030 introduces `RuntimeSpatialProjectionRepository` as the bridge from
commercial accounts to the spatial authority established by CONTRACT 028–029.

## Runtime chain

```text
Company
  -> canonical Site
  -> EntityPlacement
  -> SpatialEntityExposurePolicy
  -> RuntimeCompanySpatialView
  -> Map / Nearby / Navigation / Company Detail
```

## Runtime projection

Each production Company receives one primary commercial
`RuntimeCompanySpatialView`.

The view owns runtime access to:

- map point;
- placement quality;
- map visibility;
- nearby-ranking eligibility;
- navigation eligibility;
- Google Maps directions/search behavior.

The underlying Company remains the commercial/account entity.

## Migrated consumers

CONTRACT 030 migrates:

1. application bootstrap;
2. HomeShell spatial distribution;
3. CompaniesScreen location-quality filtering;
4. MapScreen marker/search coordinates;
5. CompanyRankingService;
6. NearbyCompaniesScreen;
7. CompanyDetailScreen location presentation and navigation.

These consumers must not use Company coordinates or Company spatial permission
flags as runtime authority.

## Legacy compatibility

The following Company fields remain physically present because older data,
tests and future rollback may still require them:

- latitude;
- longitude;
- locationQuality;
- locationConfidence;
- nearbyRankingEligible;
- navigationEligible;
- legacy spatial convenience getters.

They are marked deprecated and are compatibility/parity data only.

Their physical removal requires a later contract.

## Parity gate

Runtime projection must prove field-level parity against the existing production
snapshot before legacy data can ever be removed.

Expected production parity:

- Companies: 1,907;
- runtime map views: 1,907;
- map-visible: 1,907;
- nearby eligible: 370;
- navigation eligible: 370;
- non-Site runtime Company views: 0.

For every Company:

- runtime latitude == legacy latitude;
- runtime longitude == legacy longitude;
- runtime quality == legacy quality;
- runtime nearby permission == legacy permission;
- runtime navigation permission == legacy permission.

This parity is a migration proof, not continued runtime authority for Company.

## Explomin / ANA

The ANA well remains an Asset Placement and cannot be projected into a
RuntimeCompanySpatialView.

The Explomin commercial runtime view continues to use the canonical Site
Placement only.

## Invariants

1. Runtime Company spatial views are Site-owned.
2. Spatial exposure policy cannot be bypassed by Company fields.
3. No coordinate changes are introduced.
4. No ranking permission changes are introduced.
5. No navigation permission changes are introduced.
6. No Site identity changes are introduced.
7. Non-Site entities cannot enter Company runtime views.
8. Legacy Company spatial fields are retained only for compatibility.
9. No outreach is performed.

## Acceptance

- runtime projection coverage = 1,907 / 1,907;
- parity tests pass for every Company;
- map and nearby consumers compile against runtime spatial views;
- detail navigation uses Placement coordinates;
- migrated consumer source contains no direct Company spatial-authority access;
- analyzer and full Flutter suite pass;
- release APK/signature workflow passes.

## Closure

CONTRACT 030 closes when runtime/UI spatial decisions are driven by the
authoritative Site Placement projection while legacy Company geography remains
only as deprecated rollback data.
