# CONTRACT 022 — Operational Site Enrichment Pilot

## Objective

Reality-test CONTRACT 021 against a small, high-value set of existing Nexo
accounts and promote only reference Sites that can be supported by public
evidence.

The contract is successful even when candidates are rejected. Rejection is
preferred over inventing operational truth.

## Selection

Six existing priority-S+ accounts were reviewed:

1. Servicios Industriales de la Marina S.A.
2. Zeta Gas Andino S.A.
3. Compañía Minera Antapaccay S.A.
4. RESEMIN S.A.
5. Explomin del Perú S.A.C.
6. Master Drilling Perú S.A.C.

Selection intentionally covers shipyard, gas terminal, mining, mining equipment
and mining-services contexts.

No account was discovered from the web. Every reviewed RUC already existed in
Nexo before the pilot.

## Research boundary

Allowed:

- current official company pages;
- public government/regulatory records;
- public secondary evidence for deciding whether further proof is needed.

Forbidden:

- calls;
- emails;
- forms;
- LinkedIn requests/messages;
- guessed private data;
- silently replacing a reference Site with another physical location.

`outreach_performed=false` is part of the pilot record and validator.

## Accepted

### 20100003351 — SIMA Perú

Reference Site:
`site:20100003351:reference-1`

Decision:
`confirmedOperational`

Function:
`shipyard`

Reason:
Official SIMA material identifies Av. Contralmirante Mora 1102, Callao as its
principal operating center and describes shipyard, dock, repair and
metal-mechanics activities.

### 20262254268 — Zeta Gas Andino

Reference Site:
`site:20262254268:reference-1`

Decision:
`confirmedOperational`

Function:
`terminal`

Reason:
Official national port-system documentation identifies Terminal Portuario
Multiboyas Zeta Gas Andino at the same Oquendo / Av. Nestor Gambetta location.

### 20114915026 — Compañía Minera Antapaccay

Reference Site:
`site:20114915026:reference-1`

Decision:
`confirmedOperational`

Function:
`mine`

Reason:
Current regulatory evidence places Antapaccay installations at Campamento
Minero Tintaya and identifies the Antapaccay–Tintaya mining operation in
Espinar.

### 20100307902 — RESEMIN

Reference Site:
`site:20100307902:reference-1`

Decision:
`confirmedOperational`

Function:
`office`

Reason:
RESEMIN's current official Peru contact page confirms the same Luis Galvani
356, Ate address represented by the Site. The pilot intentionally does **not**
promote it to plant/workshop because the primary evidence reviewed does not
prove manufacturing occurs at that exact address.

## Rejected

### 20501523837 — Explomin del Perú

Outcome:
`rejected_reference_mismatch`

Explomin's current official page lists Panamericana Sur Km. 22, Huertos de
Conchán as `Sede Central`, while Nexo's current reference Site derives from
the fiscal address Lote 2 Mza B, A.V. Villa El Milagro.

CONTRACT 022 does not merge those locations.

This is evidence that a later contract must support discovery/creation of a
second Site rather than mutating Site identity.

### 20329921531 — Master Drilling Perú

Outcome:
`rejected_insufficient_primary_evidence`

Public secondary sources confirm the company and fiscal address, but the pilot
did not recover strong enough primary evidence to assert a concrete operational
Site function for the reference Site.

It remains unknown.

## In scope

- real public-source research for six existing RUCs;
- auditable pilot review artifact;
- four evidence-backed production verification records;
- explicit rejection outcomes;
- no-outreach evidence;
- regression tests over the production overlay;
- pilot-specific validator.

## Out of scope

- researching all 1,907 accounts;
- creating new Sites;
- replacing Site identity;
- moving Placements;
- improving coordinates;
- automatic crawling;
- Site CRUD UI;
- scoring verified Sites;
- changing map/ranking;
- contacting organizations.

## State change

Production changes from:

`0 confirmed operational Sites`

to:

`4 confirmed operational Sites`.

The organization-level operational-site gap count changes from:

`1,907`

to:

`1,903`.

Rejected accounts remain unknown.

## Invariants

1. Web research cannot create a new account.
2. Accepted Site must already exist in CONTRACT 020.
3. Accepted verification must pass CONTRACT 021.
4. Rejected review cannot have a production verification.
5. Current official address mismatch cannot be silently reconciled.
6. Secondary evidence alone need not be sufficient.
7. Unknown remains unknown when proof is insufficient.
8. No outreach is performed.
9. Company/geography canonical assets remain unchanged.
10. Map/ranking remain unchanged.

## Inputs

- validated CONTRACT 021 baseline;
- six existing priority-S+ accounts;
- public research evidence.

## Outputs

- four production `OperationalSiteVerification` records;
- one six-account pilot audit;
- two explicit rejection records;
- evidence-backed Site claims through CONTRACT 021.

## Acceptance

- pilot validator passes;
- six unique existing RUCs reviewed;
- four accepted;
- two rejected;
- accepted IDs equal production overlay IDs exactly;
- no outreach;
- production Site verifications = 4;
- confirmed operational Sites = 4;
- operational-site gaps = 1,903;
- rejected Explomin and Master Drilling Sites remain unknown;
- expected functions are shipyard / terminal / mine / office;
- dataset/contact/site-verification validators pass;
- analyzer passes;
- full Flutter suite passes;
- release APK builds and signature inspection passes.

## Learn

The pilot demonstrates that CONTRACT 021 can safely promote real Sites, but it
also exposes a new capability gap:

> some evidence identifies a real operating Site that is **not** the current
> reference Site.

Explomin is the concrete pilot example.

Therefore the next spatial contract should not increase sample size blindly. It
should first decide whether Nexo needs a safe **Site Discovery / Site Creation**
contract that can add a second Site without rewriting the original reference
Site.
