# CONTRACT 026 — Property / Parcel Relationship Resolution

## Objective

Resolve the relationship between an evidenced external Property and the active
canonical Site without using Site identity, address similarity or lot numbering
as substitutes for parcel evidence.

Supported outcomes:

- `part_of_site`;
- `adjacent_property`;
- `distinct_property`;
- `unknown`.

## Explomin resolution

CONTRACT 025 remains closed:

- canonical Site: `site:20501523837:reference-1`;
- absorbed alias: `site:20501523837:hq-conchan-1`.

ANA independently identifies Explomin operations at:

`Mz. B Lote 1, Asociación de Vivienda Villa El Milagro`.

The canonical Explomin Site is supported by current official evidence using:

`Mz. B Lote 2`.

The two parcel labels therefore resolve as:

`DISTINCT_PROPERTY`

with:

`operationally_related = true`.

This is a Property-level statement only.

## Non-claims

CONTRACT 026 does not claim that:

- Lote 1 is adjacent to Lote 2;
- Lote 1 is part of the canonical Site;
- Lote 1 is a second Site;
- the ANA well coordinate is the canonical Site coordinate.

Consecutive lot numbering is insufficient to prove topology.

## Evidence

The ANA technical report and resolution identify Explomin, Mz. B Lote 1,
operational use, field verification and the underlying possession/lease basis.
Current Explomin material identifies Mz. B Lote 2 in the canonical address
evidence.

## State transition

Before CONTRACT 026:

`ANA Lote 1 ↔ canonical Explomin Site = UNKNOWN`.

After CONTRACT 026:

- Property identity: distinct;
- operator relationship: same operator / operationally related;
- adjacency: unresolved;
- Site identity: unchanged;
- Site Placement: unchanged;
- active Site count: unchanged at 1,907.

## Acceptance

- relation is `distinct_property`;
- `operationally_related=true`;
- no Site is created;
- no Site is merged;
- no Site Placement is changed;
- adjacency remains unproven;
- evidence is public HTTPS;
- no outreach is performed.

## Closure

CONTRACT 026 is closed. Future work must consume this result and must not
reinterpret it as Site identity.
