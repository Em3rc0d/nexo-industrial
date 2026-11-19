# CONTRACT 010 — Trusted Knowledge Foundation

## Objective

Introduce a read-only knowledge projection over the validated Nexo baseline so
important statements can be represented as claims supported by evidence,
without rewriting `Company`, changing ranking, or migrating SQLite.

## In scope

- `KnowledgeClaim`
- `EvidenceRef`
- provenance
- confidence
- temporal mode
- freshness metadata through explicit dates
- `KnowledgeGap` for unknown direct contact
- deterministic claim/evidence identifiers
- read-only projection from current local assets

The first production projection covers:

1. audited organization geography;
2. published organization phone/email;
3. public professional role references.

## Out of scope

- Site
- AccessPath
- Opportunity
- Event/Signal
- Project
- Asset
- AI
- backend/cloud synchronization
- user editing of claims
- automatic stale thresholds
- conflict resolution UI
- replacing current `Company` fields
- changing map/ranking/contact behavior

## Domain

`KnowledgeSubjectRef -> KnowledgeClaim -> EvidenceRef`

Unknown information is represented separately as `KnowledgeGap`.

Epistemic origin and temporal mode are independent dimensions.

## Invariants

1. Claim != truth.
2. Evidence != claim.
3. Unknown != false.
4. Confidence != freshness.
5. Historical != current.
6. A production claim cannot exist without evidence.
7. Missing freshness cannot be interpreted as fresh.
8. Derived/observed/declared information cannot silently become authoritative.
9. Knowledge projection cannot create a new corporate RUC.
10. The projection is read-only and cannot mutate canonical assets.

## Inputs

- `companies.production.json`
- `companies.commercial.overlay.json.gz`
- `companies.geolocation.overlay.json`
- `companies.contact.patch.json`
- `2026-11-11_mining_people.json`

## Outputs

A `KnowledgeSnapshot` containing:

- claims;
- evidence;
- knowledge gaps.

## Persistence

None in CONTRACT 010.

The projection is rebuilt from canonical local assets. No duplicate database or
new source of truth is introduced.

## Audit

Every claim has deterministic IDs and references explicit evidence IDs.
Evidence preserves source locator and known review/observation dates.

## Acceptance

- 1,907 geography claims, one per canonical RUC.
- 299 organizations have at least one phone/email claim.
- 1,608 organizations have an explicit `organization.direct_contact` unknown gap.
- 33 professional role claims across 21 RUC.
- every claim resolves to at least one evidence record.
- public URL evidence is HTTPS.
- historical professional roles stay historical.
- current map/ranking/search/activity tests remain green.
- dataset validators, `flutter analyze`, full test suite, and APK build pass.

## Rollback

Delete the knowledge feature files and documentation changes. Because this
contract is read-only and has no persistence migration, rollback does not alter
user or canonical data.
