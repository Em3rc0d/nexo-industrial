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
Dos assets locales:

- `companies.production.json`: fuente comercial;
- `companies.geolocation.overlay.json`: auditoría geográfica por RUC.

`AssetCompanyRepository` cruza ambos en memoria.

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
