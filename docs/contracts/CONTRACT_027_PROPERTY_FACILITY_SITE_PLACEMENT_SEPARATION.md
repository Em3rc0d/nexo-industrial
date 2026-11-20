# CONTRACT 027 — Property / Operational Facility / Site / Placement Semantic Separation

## Objective

Make four concepts independently representable and auditable:

`Property / Operational Facility / Site / Placement`

without reopening CONTRACT 025 or CONTRACT 026.

- a Property is a physical/legal parcel;
- an Operational Facility is an evidenced operation located on a Property;
- a Site is Nexo's operational/commercial location identity;
- a Placement is a spatial assertion owned by a typed entity.

## Core invariant

Sharing an organization, approximate address or nearby coordinate does not imply
shared semantic identity.

## Domain

### Property

Represents parcel/property identity. Creating a Property never creates a Site.

### Operational Facility

Represents an evidenced operation on a Property, such as warehouse, plant,
office, workshop, mine or terminal. Creating a Facility never creates a Site.

### Site

Remains the Nexo operational/commercial location identity from CONTRACT 020–025.
Site identity is changed only by the appropriate Site contracts.

### Placement

A Placement answers only: "where is this entity represented spatially?"

CONTRACT 027 introduces typed entity placements for:

- Site;
- Property;
- Operational Facility;
- Asset.

The existing Site Placement model is preserved as a compatibility layer for the
1,907 active Site placements. No destructive migration is performed.

## Explomin reality case

The model now represents simultaneously:

- canonical Site: `site:20501523837:reference-1`;
- distinct Property: `property:20501523837:mz-b-lote-1`;
- Facility: Explomin warehouse on Lote 1;
- Asset: ANA-verified groundwater well;
- typed Placement: owned by the groundwater-well Asset.

The ANA coordinate is therefore not a Site Placement.

## Invariants

1. `Property != Site`.
2. `OperationalFacility != Site`.
3. `Placement != identity`.
4. `coordinate != identity`.
5. Property creation does not create a Site.
6. Facility creation does not create a Site.
7. Asset Placement does not mutate Site Placement.
8. A typed Placement must reference an existing entity of the declared type.
9. Property-to-Site relationships target active canonical Sites only.
10. Public URL evidence uses HTTPS.
11. CONTRACT 025 canonical Site and alias mapping remain unchanged.
12. CONTRACT 026 `distinct_property` result remains unchanged.
13. No new RUC is created.
14. No outreach is performed.

## Compatibility

The legacy `Placement` class remains Site-specific during this contract to
avoid a destructive migration of 1,907 production placements.

New non-Site spatial assertions use `EntityPlacement` with an explicit
`SpatialEntityType`.

A later migration may unify both representations only under its own contract,
tests and rollback plan.

## Production state change

CONTRACT 027 adds:

- 1 Property;
- 1 Operational Facility;
- 1 physical Asset;
- 1 typed Asset Placement;
- 1 Property-to-Site relationship.

It changes:

- 0 active Site identities;
- 0 existing Site Placements;
- 0 Site aliases;
- 0 RUCs.

## Acceptance

- Property/Facility overlay validates;
- typed Placement owner is the ANA well Asset;
- no typed ANA Placement targets the canonical Site;
- Property relation remains `distinct_property`;
- operational relationship remains true;
- canonical Site remains `site:20501523837:reference-1`;
- active Site count remains 1,907;
- existing Site Placement count remains 1,907;
- no second Explomin Site is created;
- CONTRACT 025 tests remain green;
- all previous validators remain green;
- analyzer and full Flutter suite pass;
- release APK/signature workflow passes.

## Closure criterion

CONTRACT 027 closes when semantic separation is encoded, production evidence is
typed correctly, regressions pass and no prior Site identity or Site Placement
state is altered.
