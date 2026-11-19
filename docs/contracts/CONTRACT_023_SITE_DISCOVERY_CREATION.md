# CONTRACT 023 — Site Discovery / Site Creation

## Objective

Allow Nexo to create a second Site identity for an existing Organization when
public evidence proves that a real location differs from the legacy
reference/fiscal Site.

CONTRACT 023 must preserve the original Site and must not invent a coordinate
Placement merely because a postal address is known.

## Reality case

CONTRACT 022 rejected Explomin's reference Site because its current official
website identifies a different Sede Central:

- existing reference Site: fiscal address at Villa El Milagro;
- discovered Site: Panamericana Sur Km. 22, Huertos de Conchán, Lima.

CONTRACT 023 creates:

`site:20501523837:hq-conchan-1`

without modifying:

`site:20501523837:reference-1`.

## Domain

`Organization -> SiteDiscoveryRecord -> Site identity -> Evidence`

A discovery emits:

`KnowledgeClaim(subject=Site, predicate=site.identity)`.

Placement is independent. If no coordinate evidence is available, the Site
receives an explicit:

`KnowledgeGap(subject=Site, predicate=site.placement)`.

## In scope

- evidence-gated Site creation for existing RUCs;
- deterministic Site IDs;
- Site identity provenance;
- duplicate/collision rejection;
- separate identity and operational verification;
- explicit missing-placement gap;
- one real production discovery (Explomin Sede Central);
- CONTRACT 021 verification of the newly created Site.

## Out of scope

- creating new Organizations/RUCs;
- coordinate geocoding;
- navigation eligibility;
- changing legacy reference Site identity;
- moving existing Placements;
- Site merge/dedup UI;
- discovery crawling at scale;
- user-facing Site CRUD;
- multi-version Site history.

## Invariants

1. Organization != Site.
2. Site != Placement.
3. Discovery cannot create a new corporate RUC.
4. Discovered Site ID must belong to its Organization.
5. Discovered Site ID cannot collide with an existing Site.
6. Discovery requires evidence.
7. Public evidence uses HTTPS.
8. Duplicate Site labels within one Organization fail closed.
9. Existing reference Site is immutable under this contract.
10. Postal address does not imply coordinate truth.
11. Missing Placement is represented as unknown, not fabricated.
12. Operational state is still granted only through CONTRACT 021.
13. A historical CONTRACT 022 rejection remains historically valid even if
    CONTRACT 023 later resolves the gap by creating a different Site.

## Production state change

Before:

- Site identities: 1,907.
- Explomin Sites: 1 reference Site.
- confirmed operational Organizations: 4.
- operational-site gaps: 1,903.

After discovery + verification:

- Site identities: 1,908.
- Placements: 1,907.
- Site placement gaps for discovered Site: 1.
- Explomin Sites: 2.
- confirmed operational Organizations: 5.
- operational-site gaps: 1,902.

The new Explomin Site is verified as `headquarters`.

Its coordinate Placement remains unknown.

## Evidence

Primary evidence:

`https://explomin.com/es/contacto/`

The official current page identifies Panamericana Sur Km. 22 Huertos de
Conchán, Lima as Explomin's Sede Central.

## Acceptance

- discovery validator passes;
- exactly one production discovery;
- total Site identities = 1,908 before verification;
- total Placements remain 1,907;
- original Explomin reference Site remains unchanged;
- discovered Explomin Site has `identityBasis=discoveredEvidence`;
- discovered Site has no Placement;
- exactly one `site.placement` gap exists for it;
- discovery emits one evidenced `site.identity` claim;
- CONTRACT 021 can verify the discovered Site without requiring Placement;
- total operationally confirmed Sites/organizations = 5;
- organization operational-site gaps = 1,902;
- CONTRACT 022 pilot remains historically 6 reviewed / 4 accepted / 2 rejected;
- dataset/contact/discovery/verification/pilot validators pass;
- analyzer and full tests pass;
- release APK and signature inspection pass.

## Learn

If CONTRACT 023 succeeds, Nexo can safely represent organizations with multiple
real Sites. The remaining spatial gap becomes coordinate/Placement enrichment,
not Site identity itself.
