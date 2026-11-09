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
- `exact_address` y `address_reference` pueden habilitar navegación si la auditoría lo autoriza.
- `interpolated_address` puede aportar a cercanía con penalización, pero no se presenta como puerta exacta.
- `street_reference` y `district_reference` son referencias visuales, no destinos de navegación.
- Google Maps no descubre cuentas. Solo sirve como fallback externo de búsqueda para cuentas ya existentes.
- El resultado de Maps no se guarda automáticamente como coordenada verificada.
- Los scores internos ordenan la experiencia, pero no se muestran numéricamente al vendedor.
