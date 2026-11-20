# CONTRACT 032 — Legacy Company Spatial Field Removal

## Objective

Physically remove the legacy spatial projection from the commercial `Company`
model after CONTRACT 031 returned `GO_FOR_REMOVAL`.

## Removed

The Company domain no longer contains:

- latitude;
- longitude;
- locationQuality;
- locationConfidence;
- nearbyRankingEligible;
- navigationEligible;
- locationDistrict;
- locationProvince;
- locationDepartment;
- map-coordinate helpers;
- distance-evidence helpers;
- Google Maps spatial helpers;
- geography-based location labels;
- legacy geography parsing.

## Repository separation

`AssetCompanyRepository` no longer loads or merges
`companies.geolocation.overlay.json`.

That dataset is **not deleted**. It remains part of the Site/Placement spatial
pipeline and is consumed independently by the spatial authority.

The commercial repository now loads only commercial/account evidence.

## Runtime ownership

All spatial behavior remains:

```text
Company
  -> canonical Site
  -> EntityPlacement
  -> SpatialEntityExposurePolicy
  -> RuntimeCompanySpatialView
```

Map coordinates, quality, regional search, nearby ranking, navigation and Google
Maps actions are sourced from `RuntimeCompanySpatialView` / `EntityPlacement`.

## Search migration

Company query matching retains commercial fields:

- name;
- RUC;
- sector;
- activity;
- commercial address text.

Geographic matching for address/district/province/department is performed by
`RuntimeCompanySpatialView.matchesQuery` against EntityPlacement metadata.
The spatial knowledge repository now carries district/province/department from
the canonical dataset into the geographic claim when the coordinate overlay
contains only coordinate/quality fields; this metadata is never projected back
into Company.

## Expected production state

- Companies: 1,907;
- runtime spatial views: 1,907;
- map-visible: 1,907;
- nearby eligible: 370;
- navigation eligible: 370;
- non-Site runtime Company views: 0.

The ANA well remains Asset-owned and outside the Company runtime projection.

## Rollback boundary

Rollback is available through the CONTRACT 031 branch and artifacts. CONTRACT
032 intentionally does not duplicate legacy fields inside Company.

## Closure

CONTRACT 032 closes only when:

1. source validation proves no legacy Company spatial fields remain;
2. commercial loading no longer reads the geolocation overlay;
3. all runtime counts remain unchanged;
4. geographic search remains functional;
5. analyzer/tests/build/signature are green.
