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
