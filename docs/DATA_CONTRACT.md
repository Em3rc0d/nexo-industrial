# Contrato de datos canónico

Nexo conserva dos capas:

1. `companies.production.json`: cuenta comercial canónica.
2. `companies.geolocation.overlay.json`: coordenadas y evidencia geográfica auditadas por RUC.

El repositorio las combina en memoria al cargar la app.

## Cuenta comercial

```json
{
  "id": "string",
  "ruc": "string",
  "name": "string",
  "sector": "string",
  "score": 0,
  "fiscal_address": "string",
  "contact": {
    "name": null,
    "role": null,
    "phone": null,
    "email": null
  }
}
```

## Overlay geográfico

```json
{
  "ruc": "string",
  "latitude": -12.0,
  "longitude": -77.0,
  "precision": "string",
  "location_quality": "exact_address | address_reference | interpolated_address | street_reference | district_reference",
  "location_confidence": "high | medium | low | very_low",
  "navigation_eligible": true,
  "nearby_ranking_eligible": true,
  "map_display_eligible": true,
  "geocoding_status": "string",
  "source": "string",
  "validation": "string"
}
```

## Reglas

- Deben existir exactamente 1,907 RUC únicos en ambas capas.
- Todo RUC debe tener coordenadas válidas.
- `nearby_ranking_eligible` es la única autoridad para permitir que una coordenada influya en el ranking por cercanía.
- `location_quality` describe la evidencia espacial; no concede elegibilidad por sí sola.
- `navigation_eligible=true` exige `nearby_ranking_eligible=true` en el dataset productivo actual.
- `exact_address` y `address_reference` pueden habilitar navegación si la auditoría lo autoriza.
- `interpolated_address` solo puede aportar a cercanía si una auditoría lo autoriza explícitamente; las 137 interpolaciones del snapshot actual tienen `nearby_ranking_eligible=false` y `navigation_eligible=false`.
- `street_reference` y `district_reference` son referencias visuales, no destinos de navegación.
- Google Maps no descubre cuentas. Solo sirve como fallback externo de búsqueda para cuentas ya existentes.
- El resultado de Maps no se guarda automáticamente como coordenada verificada.
- Los scores internos ordenan la experiencia, pero no se muestran numéricamente al vendedor.

## Capas comerciales adicionales (2026-11-11)

Además de la cuenta canónica y la auditoría geográfica, el sistema carga:

- `assets/data/companies.commercial.overlay.json.gz`: perfil comercial base con 1,907 RUC, puntuación, trabajadores SUNAT, roles objetivo, representante histórico y 270 RUC con teléfono o correo.
- `assets/data/companies.contact.patch.json`: 33 filas aceptadas adicionales, solo para RUC existentes. Contactos empresariales publicados con `source_url`, `channel_purpose`, `reviewed_on`, `source_batch` y `status=published_channel_not_contacted`. **No sobrescribe** teléfono o email base no vacío.
- `data/people_enrichment/2026-11-11_mining_people.json`: 33 profesionales públicos enlazados a 21 RUC, independientes de canales empresariales. Incluye LinkedIn, evidencia y temporalidad; los perfiles no inflan cobertura de teléfono/email.

El `AssetCompanyRepository` une cinco recursos locales sin nuevos descubrimientos externos. Se rechazan RUC desconocidos o duplicados en parches y personas. Una página de proveedores no se trata como teléfono/email directo. El estado efectivo esperado en código fuente es 299 RUC con teléfono/email y 304 si se incluyen portales. Esta integración aún no ha pasado la validación Dart/Flutter.


## Read-only knowledge projection (CONTRACT 010)

The validated assets are also projected into a non-persistent knowledge model:

- `organization.location`: 1,907 evidenced claims.
- `organization.contact.phone/email`: published direct channels only.
- `person.role_at_organization`: public professional references with evidence.
- `organization.direct_contact`: explicit unknown gap when no phone/email is loaded.

The projection never creates a RUC, never mutates canonical assets, and never
turns missing information into a negative fact. Confidence and freshness remain
separate; a missing date means freshness is unknown.


## Site / Placement projection (CONTRACT 020)

The current one-company/one-point representation is projected into a
non-persistent spatial domain:

- 1,907 deterministic reference `Site` objects;
- 1,907 `Placement` objects linked to the P1
  `organization.location` claims;
- 1,907 explicit `organization.operational_site` unknown gaps.

A verified HQ address may label a site's function as headquarters, but it does
not establish that industrial operations occur there. Fiscal addresses,
interpolated positions, street references and district references remain
evidence with their existing quality and permissions; they are not promoted to
operational sites.

This projection does not discover locations, mutate canonical geography,
change ranking, or create new RUCs.


## Operational Site Verification overlay (CONTRACT 021)

`assets/data/sites.verified.overlay.json` is the only production input allowed
to promote a reference Site to `confirmedOperational` or
`confirmedNotOperational`.

Each record must identify:

- verification ID;
- existing Site ID;
- owning organization RUC;
- decision;
- concrete Site function when operational;
- verification method;
- verification date and optional validity range;
- one or more evidence records.

Public URL evidence must use HTTPS. A fiscal address, precise coordinate,
company name, commercial score or map pin cannot create operational truth.

The initial production overlay contains **0 records**. Therefore the 1,907
reference Sites remain operationally unknown until evidence-backed
verifications are added.


## Operational Site Enrichment Pilot (CONTRACT 022)

The first production enrichment pilot reviews six existing S+ accounts and
performs no outreach.

Results:

- reviewed: 6;
- accepted operational Site verifications: 4;
- rejected/unresolved: 2;
- confirmed operational Sites after pilot: 4;
- remaining organization operational-site gaps: 1,903.

The accepted production verifications are exactly the records present in
`assets/data/sites.verified.overlay.json`.

The audit of both accepted and rejected candidates is stored in
`data/site_enrichment/2026-11-19_operational_site_pilot.json`.

A rejected record must never be interpreted as a negative fact about the whole
organization. In particular, a reference-address mismatch indicates the need
for a separate Site identity rather than permission to overwrite the existing
Site.


## Site Discovery / Site Creation overlay (CONTRACT 023)

`assets/data/sites.discovered.overlay.json` may create additional Site
identities only for RUCs already present in the canonical company dataset.

Each discovery requires:

- unique discovery ID;
- unique Site ID under the owning RUC;
- display label/address;
- Site function;
- discovery method and date;
- one or more evidence records.

A discovery cannot overwrite or reuse `site:<ruc>:reference-1`.

Public URL evidence must use HTTPS.

CONTRACT 023 does not infer coordinates from postal addresses. A discovered
Site without coordinate evidence is created with no Placement and an explicit
`site.placement = unknown` gap.

Production currently contains one discovery:

- Explomin del Perú S.A.C. — Sede Central at Panamericana Sur Km. 22, Huertos
  de Conchán.

After CONTRACT 023 there are 1,908 Site identities and 1,907 Placements.


## Placement Verification overlay (CONTRACT 024)

`assets/data/site.placement.verified.overlay.json` is the only CONTRACT 024
input allowed to create or replace evidence-backed Site Placements.

Each accepted record requires:

- existing Site ID;
- latitude/longitude;
- placement quality;
- confidence;
- verification method/date;
- explicit proximity/navigation permissions;
- evidence;
- `supersedes_placement_id` when replacing an existing Placement.

`property_reference` is non-actionable for both proximity ranking and direct
navigation.

The initial production overlay contains **0 records**. The Explomin pilot found
an authoritative ANA coordinate (UTM WGS84 Zone 18S: E 287610, N 8646165;
approximately -12.239774, -76.952451 WGS84), but rejected assignment because
the evidence does not yet prove which current Nexo Site identity owns that
coordinate.

The audit is stored in
`data/site_enrichment/2026-11-19_placement_enrichment_pilot.json`.
