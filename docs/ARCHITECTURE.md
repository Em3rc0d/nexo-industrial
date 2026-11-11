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

### Ranking
Combina:
- potencial interno;
- cercanía;
- peso de evidencia.

Solo exacta/referencia/interpolada pueden usar distancia. La interpolación recibe penalización. Calle/distrito no compiten por cercanía.

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
