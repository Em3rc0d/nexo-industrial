# CONTRACT 024 — Placement Verification / Coordinate Enrichment

## Objective

Introduce an evidence-gated mechanism that can create or replace a Site
Placement only when the Site-to-coordinate association is sufficiently proven.

The contract must distinguish:

- coordinate precision;
- Site identity certainty;
- ranking permission;
- navigation permission.

A precise coordinate for a nearby feature is not automatically a valid Site
Placement.

## Reality case — Explomin

CONTRACT 023 created a second Site identity for Explomin's current published
headquarters label:

`site:20501523837:hq-conchan-1`.

During CONTRACT 024, an official ANA technical report was found for Explomin.
It documents a field-verified, used well associated with an Explomin property
and warehouse-related activity at:

`Mz. B Lote 1, Asociación de Vivienda Villa El Milagro`

with:

- CRS: UTM WGS 84 / Zone 18S;
- Easting: 287,610 m;
- Northing: 8,646,165 m.

The deterministic EPSG:32718 -> EPSG:4326 transformation is approximately:

- latitude: -12.239774;
- longitude: -76.952451.

However, Nexo currently has:

- legacy reference Site based on Mz. B Lote 2;
- discovered headquarters Site described as Panamericana Sur Km. 22,
  Huertos de Conchán.

The ANA coordinate is authoritative for the documented physical feature, but
the evidence does not unambiguously prove which current Nexo Site identity
owns that coordinate.

Therefore the production enrichment is rejected fail-closed.

## Domain

`Site -> PlacementVerificationRecord -> Placement -> Evidence`

Accepted verification emits:

`KnowledgeClaim(subject=Site, predicate=site.placement)`.

## New quality

`property_reference`

This represents an evidence-backed point associated with a property/site area,
but not a validated entrance or exact navigable destination.

A `property_reference` can never enable:

- proximity ranking;
- direct navigation.

## In scope

- Placement verification domain;
- evidence-gated coordinate creation;
- explicit replacement semantics through `supersedesPlacementId`;
- Site placement KnowledgeClaim;
- removal of `site.placement` gap only after accepted verification;
- non-actionable `property_reference` quality;
- real Explomin coordinate-enrichment reality test;
- deterministic UTM -> WGS84 validation;
- explicit rejection when Site identity is ambiguous.

## Out of scope

- resolving whether Explomin's two current Site identities are the same physical
  complex;
- Google Places;
- new-account discovery;
- automatic geocoding at scale;
- entrance detection;
- routing;
- changing ranking weights;
- changing current map UI;
- assigning the ANA coordinate to a Site without proof.

## Invariants

1. Site != Placement.
2. Coordinate evidence != Site identity evidence.
3. Exact coordinate != exact Site association.
4. Placement verification requires an existing Site.
5. Placement verification requires evidence.
6. Navigation eligibility implies nearby-ranking eligibility.
7. `property_reference` cannot enable nearby ranking.
8. `property_reference` cannot enable navigation.
9. Replacing an existing Placement requires explicit supersedes ID.
10. Missing Placement remains unknown.
11. Rejected coordinate candidate cannot mutate production Placement.
12. Public evidence uses HTTPS.
13. No new RUC is created.
14. No outreach is performed.

## Production state

The production placement-verification overlay begins with zero accepted records.

Therefore after CONTRACT 024:

- Site identities: 1,908;
- Placements: 1,907;
- Explomin discovered HQ Placement: still unknown;
- placement verification records: 0;
- accepted coordinate enrichments: 0.

This is intentional.

## Pilot result

Reviewed:

1 coordinate candidate.

Accepted:

0.

Rejected:

1 — `rejected_site_identity_ambiguous`.

The coordinate itself is not rejected as inaccurate. The unresolved element is
which Nexo Site identity it belongs to.

## Acceptance

- placement-verification validator passes;
- placement-enrichment pilot validator passes;
- production placement overlay has zero accepted records;
- current 1,907 Placements remain unchanged;
- Explomin discovered HQ retains one `site.placement` unknown gap;
- controlled accepted fixture can create a Placement and resolve that gap;
- replacing legacy Placement requires explicit supersedes ID;
- property reference cannot enable proximity or navigation;
- navigation cannot bypass nearby eligibility;
- unknown Site and missing evidence fail closed;
- UTM 287610 / 8646165 Zone 18S deterministically converts to approximately
  -12.239774 / -76.952451;
- dataset/contact/discovery/site-verification/pilot validators remain green;
- analyzer and full Flutter suite pass;
- release APK builds and signature inspection passes.

## Learn

CONTRACT 024 demonstrates that coordinate quality and Site identity certainty
are independent dimensions.

The next spatial problem is not geocoding.

It is **Site Identity Reconciliation**: determine whether the legacy Villa El
Milagro reference, the Huertos de Conchán headquarters label and the ANA
operational property describe one complex, adjacent Sites, or distinct Sites.
Only after that reconciliation may the authoritative coordinate be assigned
without corrupting identity.
