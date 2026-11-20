# CONTRACT 029 — Spatial Entity Map / UX Exposure Policy

## Objective

Define which spatial entity types may appear on commercial map and UX surfaces
after CONTRACT 028 established a unified Placement authority.

CONTRACT 029 is an exposure policy. It does not change entity identity,
coordinates, Placement ownership, ranking scores or navigation targets.

## Input authority

All decisions consume `UnifiedSpatialPlacementRepository`.

No screen or policy may infer exposure from coordinates alone.

## Surfaces

The policy evaluates four surfaces:

- `commercialMap`;
- `companyDetail`;
- `nearbyRanking`;
- `navigation`.

Each Placement receives one of:

- `hidden`;
- `contextual`;
- `primary`.

CONTRACT 029 currently uses `primary` or `hidden`. Contextual non-Site
exposure is reserved for a later contract with dedicated UX semantics.

## Commercial map

Only canonical `Site` Placements may become primary commercial markers.

Requirements:

1. `entity_type=site`;
2. `map_display_eligible=true`.

Production result:

- 1,907 primary Site markers;
- 0 Property markers;
- 0 OperationalFacility markers;
- 0 Asset markers.

This preserves the current commercial map coverage without exposing internal
spatial evidence as customer/prospect destinations.

## Nearby ranking

A Placement may participate only when:

1. it is a Site;
2. `nearby_ranking_eligible=true`.

Production exposure remains 370 Sites.

The policy cannot promote an ineligible Placement.

## Navigation

Direct navigation requires:

1. Site ownership;
2. `navigation_eligible=true`.

Production exposure remains 370 Sites.

Property, Facility and Asset coordinates cannot become direct destinations
under CONTRACT 029.

## Company detail

The Site remains the primary commercial spatial representation.

Non-Site spatial entities remain hidden in the current commercial UX. This is
deliberate: a Property, Facility or Asset may be valid evidence without being a
safe or useful commercial destination.

Future contextual disclosure requires a separate contract defining labels,
provenance presentation, user intent and action boundaries.

## Explomin / ANA case

The ANA groundwater well remains a valid unified Asset Placement but receives:

- commercial map: hidden;
- company detail: hidden;
- nearby ranking: hidden;
- navigation: hidden.

Its evidence remains available in the data model. Hiding it from commercial UX
does not delete or weaken the evidence.

## Invariants

1. Exposure policy cannot change Placement permissions.
2. Exposure policy cannot change Site identity.
3. Exposure policy cannot create a Site.
4. A coordinate cannot imply commercial visibility.
5. A non-Site entity cannot enter ranking or navigation.
6. Hidden evidence remains preserved in the spatial model.
7. CONTRACT 025–028 conclusions remain unchanged.
8. No outreach is performed.

## Acceptance

- map exposure = exactly 1,907 Site markers;
- non-Site map exposure = 0;
- nearby ranking exposure = 370 Sites;
- navigation exposure = 370 Sites;
- ANA Asset is hidden on all four surfaces;
- full analyzer/test suite passes;
- release APK/signature workflow passes.

## Closure

CONTRACT 029 closes when the exposure policy is deterministic, fail-closed,
fully tested and proven not to expand any Placement permission.
