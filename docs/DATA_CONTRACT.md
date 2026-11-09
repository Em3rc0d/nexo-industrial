# Contrato de datos canónico

Cada cuenta exportada a Nexo debe cumplir:

```json
{
  "id": "string",
  "ruc": "string",
  "name": "string",
  "sector": "string",
  "activity": "string",
  "opportunity_reason": "string",
  "suggested_next_step": "string",
  "address": "string",
  "latitude": -12.0,
  "longitude": -77.0,
  "location_confidence": "confirmed | fiscal_only | uncertain",
  "internal_potential": 0.0,
  "aurora_products": [],
  "sigma_products": [],
  "contact": {"name": null, "role": null, "phone": null, "email": null},
  "source": "string",
  "source_updated_at": "ISO-8601",
  "management_status": "string | null"
}
```

## Reglas

- El dataset maestro propio es la fuente canónica.
- Google Maps/Places no descubre prospectos.
- Solo confirmed y fiscal_only entran al mapa por defecto.
- uncertain debe sanearse antes de competir geográficamente.
- Los contactos vacíos permanecen vacíos.
- internal_potential está entre 0 y 1, es interno y nunca se muestra como score al vendedor.
- Las sugerencias Aurora/Sigma son hipótesis comerciales, no especificaciones técnicas de un proyecto concreto.
- source y source_updated_at son obligatorios.
