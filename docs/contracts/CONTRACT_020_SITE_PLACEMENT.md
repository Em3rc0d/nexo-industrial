# CONTRACT 020 — Site / Placement Foundation

## Objective

Separate Organization, Site and Placement so Nexo can evolve beyond the
assumption that one company equals one map pin.

The first slice is intentionally conservative: it creates reference sites from
the currently validated address/geography evidence, while preserving an
explicit unknown for whether those sites are actually operational industrial
locations.

## In scope

- `Site`
- `Placement`
- independent site identity
- site-to-organization association
- audited placement quality/confidence
- proximity/navigation eligibility
- provenance through the P1 knowledge claim/evidence chain
- explicit unknown operational-site gap
- support for future multiple sites per organization

## Out of scope

- discovering new plants/mines/warehouses
- external site enrichment
- changing current map UI
- moving the canonical map off `Company`
- Site CRUD
- relocation/history
- operational-site confirmation workflow
- assets
- projects
- AccessPath
- Opportunity
- backend/cloud
- changing ranking weights or geography data

## Domain

`Organization -> Site -> Placement -> Location evidence`

Current projection uses deterministic IDs:

- `site:<ruc>:reference-1`
- `placement:<site-id>:current`

A site may be based on:

- verified headquarters address;
- fiscal address;
- geographic reference.

That basis does not prove that industrial operations occur there.

## Invariants

1. Organization != Site.
2. Site != Placement.
3. Organization != coordinate.
4. A fiscal address does not imply operational location.
5. A precise coordinate does not imply operational location.
6. Placement quality does not override audited eligibility.
7. Every placement must reference an existing site.
8. Every placement must preserve its source knowledge claim and evidence.
9. Current projected sites default to operational status = unknown.
10. Site identity must survive future placement changes.
11. Multiple sites per organization must remain architecturally possible.
12. No new RUC may be created by this projection.

## Inputs

- validated P1 `KnowledgeSnapshot`;
- validated `Company` projection.

## Outputs

A read-only `SiteSnapshot` containing:

- sites;
- placements;
- operational-site knowledge gaps.

## Persistence

None in CONTRACT 020.

No SQLite migration and no canonical dataset rewrite.

## Audit

Every placement references the P1 `organization.location` claim and its
evidence IDs.

## Acceptance

- 1,907 reference sites.
- 1,907 placements.
- 1,907 unique organization associations.
- 1,907 explicit operational-site unknown gaps.
- 0 sites marked operationally confirmed.
- placement-quality counts remain 334 / 36 / 137 / 551 / 849.
- nearby/navigation eligible counts remain 370 / 370.
- 137 interpolated placements remain non-eligible.
- every placement references a site and evidence-backed claim.
- verified HQ references may be classified as headquarters, but still remain
  operationally unknown.
- current baseline tests remain green.
- dataset validators, analyzer, full tests and APK build pass.

## Rollback

Delete the Site/Placement projection and documentation changes. No persisted
user or canonical data is affected.
