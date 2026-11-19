# CONTRACT 021 — Operational Site Verification

## Objective

Introduce one auditable mechanism that can change a reference Site from
`operationalStatus=unknown` to either:

- `confirmedOperational`; or
- `confirmedNotOperational`.

The change must require explicit evidence and must never be inferred merely
from an address, coordinate precision, company name or commercial score.

## In scope

- `OperationalSiteVerification`
- explicit operational / not-operational decision
- concrete Site function for operational confirmations
- verification method
- verifier/reviewer metadata
- verified date
- validity range
- evidence references
- one current verification per Site
- Site knowledge claim generation
- organization-level operational-site gap resolution when at least one Site is
  actually confirmed operational
- production overlay validation

## Out of scope

- discovering sites automatically
- web crawling / Places discovery
- bulk site research
- Site CRUD UI
- field verification UI
- Site relocation history
- multiple historical verification revisions per Site
- automatic expiration
- changing map/ranking
- AccessPath
- Opportunity
- Projects
- Assets
- backend/cloud synchronization

## Domain

`Organization -> Site -> OperationalSiteVerification -> Evidence`

A successful verification also emits:

`KnowledgeClaim(subject=Site, predicate=site.operational_status)`

## Production state

The production overlay begins with zero records.

This is intentional: current Nexo evidence does not yet justify promoting any
of the 1,907 reference Sites to confirmed industrial operating Sites.

## Invariants

1. Fiscal address != operational Site.
2. Precise coordinate != operational Site.
3. Verification must reference an existing Site.
4. Verification RUC must match the Site owner.
5. Operational confirmation requires a concrete Site function.
6. Every verification requires evidence.
7. Public URL evidence must use HTTPS.
8. Verification preserves Site identity.
9. A confirmed-not-operational reference Site does not prove the organization
   lacks another operational Site.
10. Organization operational-site gap is removed only when at least one Site is
    confirmed operational.
11. Current CONTRACT 021 allows only one current verification per Site.
12. Validity end cannot precede validity start.
13. Verification produces an evidence-backed Site knowledge claim.
14. No new corporate RUC is created.
15. Map/ranking behavior remains unchanged.

## Inputs

- validated CONTRACT 020 SiteSnapshot;
- `assets/data/sites.verified.overlay.json`.

## Outputs

`SiteVerificationResult` containing:

- updated SiteSnapshot;
- operational verifications;
- Site knowledge claims;
- verification evidence.

## State changes

Production Site state may change only through explicit overlay records.

The canonical company/geography assets are not rewritten.

## Authorization

CONTRACT 021 models verification as an audited input. It does not yet expose a
UI that authorizes or writes verifications.

## Persistence

The current persistent representation is the versioned overlay asset.

No SQLite migration is introduced.

## Failure modes

The contract fails closed on:

- unknown Site;
- RUC/Site mismatch;
- missing evidence;
- unsupported decision/function/method;
- operational confirmation with unknown function;
- invalid date;
- invalid validity interval;
- duplicate current Site verification;
- conflicting evidence IDs;
- non-HTTPS public URL evidence.

## Audit

Each verification carries:

- deterministic verification ID;
- Site ID;
- organization RUC;
- decision;
- Site function;
- method;
- verified_at;
- validity range;
- reviewer;
- notes;
- evidence.

## Acceptance

Production:
- overlay validates;
- 0 verification records;
- 0 operationally confirmed Sites remain until evidence is supplied;
- 1,907 organization operational-site gaps remain.

Controlled tests:
- operational verification preserves Site identity;
- one operational verification resolves exactly one organization gap;
- confirmed-not-operational does not remove the organization gap;
- Site claim is generated with evidence;
- field observation maps to observed knowledge;
- missing evidence is rejected;
- unknown function for operational Site is rejected;
- RUC/Site mismatch is rejected;
- invalid validity is rejected;
- duplicate current verification is rejected.

Regression:
- dataset validators pass;
- CONTRACT 020 invariants remain green;
- `flutter analyze` passes;
- full Flutter suite passes;
- APK build and signature inspection pass.

## Rollback

Remove the verification overlay/domain/repository/validator and revert the
KnowledgeSubjectType extension. No user data or canonical company/geography
data must be changed.
