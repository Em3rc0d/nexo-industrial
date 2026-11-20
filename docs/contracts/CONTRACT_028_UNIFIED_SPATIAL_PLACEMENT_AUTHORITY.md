# CONTRACT 028 — Unified Spatial Placement Authority

## Objective

Establish one authorized read model for spatial assertions while preserving
every previously validated Site Placement exactly.

CONTRACT 028 does not delete the legacy `Placement` model. It demotes it to a
rollback/compatibility adapter and introduces
`UnifiedSpatialPlacementRepository` as the authority for new spatial
consumers.

## Authority

The unified authority returns `EntityPlacement` for:

- Site;
- Property;
- Operational Facility;
- Asset.

Every legacy Site Placement is projected as:

`entity_type = site`

with its existing Placement ID retained.

## Lossless Site migration

The migration must preserve exactly:

- Placement ID;
- Site ID as `entity_id`;
- latitude;
- longitude;
- PlacementQuality;
- confidence;
- map-display eligibility;
- nearby-ranking eligibility;
- navigation eligibility;
- source claim;
- evidence IDs;
- address/district/province/department;
- temporal metadata.

Production cardinality remains:

- active Sites: 1,907;
- legacy Site Placements: 1,907;
- unified Site Placements: 1,907.

No Site is created, deleted, merged or re-identified.

## Non-Site Placement

The CONTRACT 027 ANA well remains:

- `entity_type=asset`;
- owned by `asset:20501523837:mz-b-lote-1:groundwater-well`;
- independent from the canonical Explomin Site Placement.

Its commercial permissions are explicitly fail-closed:

- `map_display_eligible=false`;
- `nearby_ranking_eligible=false`;
- `navigation_eligible=false`.

CONTRACT 028 therefore produces 1,908 total unified Placements:

- 1,907 Site;
- 1 Asset.

## Eligibility invariants

A Placement cannot:

1. enable navigation when nearby ranking is disabled;
2. become actionable when map display is disabled;
3. make `property_reference` actionable;
4. target a non-canonical Site after reconciliation.

The 1,907 Site Placements preserve the current production permissions:

- map display: 1,907;
- nearby ranking: 370;
- navigation: 370.

## Rollback

The migration is additive. The legacy Site `Placement` collection is not
deleted or rewritten.

Rollback is therefore deterministic: consumers can switch back to the
pre-CONTRACT-028 SiteSnapshot representation without data conversion.

Removal of the legacy adapter requires a separate future contract.

## Non-goals

CONTRACT 028 does not:

- expose Property/Facility/Asset on the commercial map UI;
- change ranking;
- change navigation;
- create a Site from a Property or Facility;
- reinterpret CONTRACT 025, 026 or 027;
- perform outreach.

## Acceptance

- 1,907 legacy Site Placements map one-to-one to 1,907 unified Site Placements;
- field-by-field parity tests pass;
- total unified Placements = 1,908;
- ANA remains Asset-owned and non-actionable;
- active Sites remain 1,907;
- Site alias count remains 1;
- analyzer and full Flutter suite pass;
- release APK/signature workflow passes.

## Closure

CONTRACT 028 closes only when the unified authority is production-readable,
lossless parity is proven, rollback remains available and all previous
contracts remain green.
