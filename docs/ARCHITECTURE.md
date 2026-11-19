# Arquitectura — Nexo Industrial MVP 1.0

## Objetivo

Aplicación local-first para prospección industrial en campo, desacoplada de proveedores de descubrimiento comercial.

## Capas

### Domain
`Company` representa la cuenta canónica y su evidencia geográfica.

Calidad geográfica:
- exactAddress;
- addressReference;
- interpolatedAddress;
- streetReference;
- districtReference.

### Data
Cinco assets locales:

- `companies.production.json`: única lista canónica de 1,907 cuentas;
- `companies.geolocation.overlay.json`: auditoría geográfica por RUC;
- `companies.commercial.overlay.json.gz`: datos comerciales y contactos base;
- `companies.contact.patch.json`: contactos publicados adicionales, aceptados por RUC y sin sobrescribir canales existentes;
- `data/people_enrichment/2026-11-11_mining_people.json`: referencias profesionales públicas independientes.

`AssetCompanyRepository` cruza las capas en memoria. El parche contiene solo RUC ya existentes: el teléfono/email base tiene precedencia. Los contactos corporativos no se mezclan con perfiles personales, y no hay tráfico de red al abrir la app salvo los servicios opcionales de mapas existentes.

### Knowledge

CONTRACT 010 introduces a read-only knowledge projection over the existing
assets. `KnowledgeClaim` is separate from `EvidenceRef`; missing direct
contact is represented as `KnowledgeGap` rather than false. Epistemic origin
(authoritative/observed/declared/derived/hypothesis) is independent from
temporal mode (current/historical/expected/simulated), and known dates are
preserved without inventing a global stale threshold.

This layer does not replace `Company` or create a second persisted source of
truth.

### Sites / Placement

CONTRACT 020 introduces a read-only spatial domain projection that separates
`Organization`, `Site` and `Placement`.

Current data creates one deterministic **reference site** per organization only
as a migration bridge from the legacy one-company/one-point model. The site
identity is independent from its placement so future organizations may own or
operate multiple sites and a site may later change placement without changing
identity.

Current fiscal/HQ/geographic references do **not** prove an operating industrial
site. Every projected site therefore keeps `operationalStatus=unknown` and an
explicit `organization.operational_site` knowledge gap. Placement preserves
the P1 claim/evidence chain, geographic quality, confidence and audited
navigation/proximity eligibility.

### Operational Site Verification

CONTRACT 021 adds an explicit verification layer on top of the Site/Placement
projection. A reference Site remains operationally unknown until an
`OperationalSiteVerification` with evidence says otherwise.

Verification preserves Site identity, records method/date/validity/evidence,
and emits a P1 `KnowledgeClaim` with
`predicate=site.operational_status`. Confirming that one reference address is
not operational does not imply the organization lacks another operating Site;
the organization-level gap is resolved only when at least one Site is confirmed
operational.

The production verification overlay currently contains zero records. This is a
valid state: current evidence does not justify inventing operating locations.

### Operational Site Enrichment Pilot

CONTRACT 022 applies the verification mechanism to a controlled production
sample. Research remains external evidence only; accepted Sites are existing
CONTRACT 020 identities and are promoted exclusively through CONTRACT 021.

The pilot currently verifies four operational Sites and keeps two reviewed
accounts unresolved. A rejected reference mismatch is not repaired by changing
Site identity: it is evidence that Nexo needs a future Site discovery/creation
capability for organizations whose real operating location differs from their
reference/fiscal Site.

### Site Discovery / Site Creation

CONTRACT 023 introduces evidence-gated creation of additional Site identities
for existing Organizations. It is designed for the case where current public
evidence identifies a real location that is different from the legacy
reference/fiscal Site.

Discovery never mutates `site:<ruc>:reference-1`. It creates a new Site with
its own deterministic identity and a `site.identity` KnowledgeClaim.

Site and Placement remain independent. CONTRACT 023 deliberately allows a
new Site to exist without coordinates when address-level evidence is strong
but coordinate evidence is not. That state is represented as an explicit
`site.placement` KnowledgeGap rather than fabricated latitude/longitude.

The first production case creates Explomin's current Huertos de Conchán Sede
Central as a second Site and then verifies that Site through CONTRACT 021.

### Placement Verification / Coordinate Enrichment

CONTRACT 024 adds an evidence-gated layer between Site discovery and downstream
operational use of coordinates.

A `PlacementVerificationRecord` may create a new Placement for a Site or
explicitly supersede an existing Placement. Replacement is never implicit.

The layer separates four independent questions:

1. is the coordinate itself well supported?;
2. is the coordinate unambiguously associated with this Site identity?;
3. may the point participate in proximity ranking?;
4. may the point be used for direct navigation?

`property_reference` is introduced for an evidence-backed property/area point
that is not a validated entrance or exact destination. It cannot enable
proximity ranking or navigation.

The first reality test found authoritative ANA coordinates associated with an
Explomin operational property, but the current Nexo Site identities do not yet
support an unambiguous Site↔coordinate assignment. Production therefore remains
unchanged and the candidate is recorded as rejected rather than guessed.

### Ranking
Combina:
- potencial interno;
- cercanía;
- peso de evidencia.

`nearby_ranking_eligible` es la autoridad para decidir si una cuenta puede usar distancia. `LocationQuality` no puede anular una inelegibilidad auditada; únicamente pondera la evidencia después del gate. En el snapshot actual las 137 interpolaciones no compiten por cercanía. Calle/distrito tampoco compiten.

### Map
`flutter_map` + clustering. El mapa es visualización; no descubre prospectos.

### Activity
SQLite on-device, esquema v2:
- tipo;
- resultado;
- nota;
- siguiente paso;
- estado;
- seguimiento;
- fecha de creación.

La migración desde v1 conserva actividades existentes.

## Escala

1,907 cuentas son manejables localmente.

Si el dataset crece a decenas de miles:
- mover filtrado espacial a SQLite;
- usar R-tree;
- mantener el dataset maestro como fuente controlada.

## Servicios externos

- OpenStreetMap: tiles/cartografía.
- Google Maps URL: navegación o búsqueda externa.
- No Google Places/Search para descubrir cuentas.
- Sin backend obligatorio.

## Android

El directorio Android se genera localmente mediante `tool/bootstrap_android.sh`. El build release no usa GitHub Actions.
