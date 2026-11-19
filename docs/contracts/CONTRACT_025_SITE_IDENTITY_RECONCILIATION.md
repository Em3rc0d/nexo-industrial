# CONTRACT 025 — Site Identity Reconciliation

## Objective

Resolve duplicate or conflicting Site identities without deleting discovery
history or fabricating physical relationships.

The contract classifies Site-to-Site identity relationships as:

- `same_site`;
- `adjacent_site`;
- `distinct_site`;
- `unknown`.

Only `same_site` may collapse two active Site identities into one canonical
Site. The absorbed Site remains preserved as an alias/audit identity.

## Reality case — Explomin

Nexo entered CONTRACT 025 with two Site identities:

1. `site:20501523837:reference-1`
   - based on Mz. B Lote 2, A.V. Villa El Milagro;
   - owns the legacy district-reference Placement.

2. `site:20501523837:hq-conchan-1`
   - discovered from Explomin's current public contact material;
   - labelled Panamericana Sur Km. 22 Huertos de Conchán;
   - no Placement.

A current official Explomin privacy-policy page contains both:

- the formal correspondence address
  `Mz. B, Lote 2, A.V. Villa El Milagro (Km. 22.5 de la Panamericana Sur),
  Villa El Salvador`;
- the footer/current `Sede Central`
  `Panamericana Sur Km. 22 Huertos de Conchán - Lima, 15842`.

Because both descriptions are published contemporaneously by Explomin itself,
CONTRACT 025 classifies the two Nexo Sites as:

`SAME_SITE`

with:

`site:20501523837:reference-1`

as canonical identity.

The reconciliation is a derived high-confidence claim, not a claim that the two
address strings are literally identical cadastral descriptions.

## ANA property

ANA separately verifies an Explomin operational property/warehouse-related well
at:

`Mz. B Lote 1, Asociación de Vivienda Villa El Milagro`

with UTM WGS84 Zone 18S coordinates:

- E 287610;
- N 8646165.

CONTRACT 025 does **not** classify this external property as SAME_SITE,
ADJACENT_SITE or DISTINCT_SITE relative to the canonical Explomin Site.

Its relationship remains:

`UNKNOWN`.

Lote numbering and geographic naming are not sufficient evidence of parcel
topology or Site identity.

## Domain

`Site -> SiteIdentityReconciliationRecord -> Evidence`

A reconciliation emits:

`KnowledgeClaim(subject=Site, predicate=site.identity_relation)`.

For `SAME_SITE`, the result also produces a `SiteAlias`:

`alias Site ID -> canonical Site ID`.

## Active-state semantics

Discovery history remains immutable:

- discovery-layer Site identities: 1,908.

Active reconciled state becomes:

- active Site identities: 1,907;
- Placements: 1,907;
- active Site aliases: 1.

The alias Site is removed only from the active snapshot. Its discovery record,
label and reconciliation evidence remain auditable.

## Canonical selection

The legacy reference Site remains canonical because:

1. it predates the duplicate discovery identity;
2. it already owns the current Placement history;
3. absorbing it into the discovered alias would require moving an existing
   Placement and would violate the fail-closed merge invariant.

The canonical Site adopts the richer `headquarters` function from its alias
when its existing function is `unknown`.

## Operational truth

The CONTRACT 023 Explomin operational verification is migrated from the alias
Site ID to the canonical Site ID.

After CONTRACT 025:

- Explomin active Sites: 1;
- canonical Site function: headquarters;
- canonical Site operational status after CONTRACT 021: confirmedOperational;
- alias Site is not writable by later Placement/verification contracts.

## In scope

- Site identity-relation domain;
- evidence-backed SAME/ADJACENT/DISTINCT/UNKNOWN classification;
- canonical Site selection for SAME_SITE;
- alias preservation;
- active snapshot merge;
- migration of current Explomin operational verification to canonical Site;
- prevention of future writes to absorbed aliases;
- explicit UNKNOWN assessment for the ANA Lote 1 property;
- reconciliation validator and regression tests.

## Out of scope

- cadastral parcel topology;
- proving Lote 1 adjacency;
- assigning ANA coordinates;
- automatically merging arbitrary Sites;
- destructive deletion of discovery history;
- UI for alias/reconciliation management;
- coordinate changes;
- ranking changes;
- navigation changes.

## Invariants

1. Site identity relation != geographic proximity.
2. SAME_SITE requires explicit evidence.
3. SAME_SITE requires a canonical Site from the reconciled pair.
4. Both Sites must belong to the same Organization.
5. Alias Site cannot own an active Placement at merge time.
6. Alias Site cannot carry unresolved non-placement gaps at merge time.
7. Discovery history is preserved.
8. Active alias Site cannot receive later Placement verification.
9. Active alias Site cannot receive later operational verification.
10. UNKNOWN does not mutate either Site.
11. Only SAME_SITE may define a canonical Site.
12. Public evidence uses HTTPS.
13. No new RUC is created.
14. No outreach is performed.
15. Coordinate candidate from CONTRACT 024 remains unassigned.

## Production state change

Before reconciliation:

- discovery identities: 1,908;
- active identities: 1,908;
- Placements: 1,907;
- Explomin active Sites: 2.

After reconciliation:

- discovery identities: 1,908;
- active identities: 1,907;
- Placements: 1,907;
- Explomin active Sites: 1;
- Site aliases: 1;
- accepted Placement verifications: 0.

Operational state remains:

- confirmed operational organizations: 5;
- organization operational-site gaps: 1,902.

## Acceptance

- reconciliation validator passes;
- one production reconciliation exists;
- relation = SAME_SITE;
- canonical Site = reference-1;
- one active alias exists;
- active Site count = 1,907;
- discovery layer remains 1,908;
- Placement count remains 1,907;
- Explomin active Site count = 1;
- canonical Site preserves the existing Placement;
- canonical Site adopts headquarters function;
- alias Site disappears from active snapshot;
- alias label remains in reconciliation metadata;
- reconciliation emits one high-confidence derived claim with two evidence refs;
- ANA external-property assessment remains UNKNOWN;
- no outreach;
- site/placement validators reject writes to absorbed alias;
- five operational Site verifications remain valid;
- zero placement-verification records remain;
- all previous dataset and pilot validators pass;
- analyzer and full Flutter suite pass;
- release APK and signature inspection pass.

## Learn

The current evidence supports collapsing the duplicate Nexo identity created by
address-language differences.

It does **not** yet support assigning the ANA Lote 1 coordinate.

The remaining spatial question is now narrower:

> Is the ANA Lote 1 operational property part of the canonical Explomin Site,
> an adjacent parcel of the same industrial complex, or a separate Site?

That requires parcel/property evidence, not another address alias heuristic.
