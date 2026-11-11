# Nexo Industrial — snapshot completo de datos (2026-11-10)

Este snapshot conserva **todos los artefactos de datos que seguían disponibles** al cerrar la sesión de geolocalización de las 1,907 cuentas.

## Integridad del archivo

Archivo reconstruido:

`Nexo_Industrial_data_snapshot_2026-11-10.tar.gz`

SHA-256:

`3506bf1adb25106c8b230c9492e37cf01c2b2d67f9be1f40df73452a5ea80e44`

Tamaño: **7,214,026 bytes**.

El archivo está almacenado como 28 partes Base64 para evitar límites del conector GitHub. `restore.sh` concatena, decodifica, verifica SHA-256 y extrae el snapshot.

## Contenido

- Master_MK2_MAPS_1907_2026-11-10.json
- Master_MK2_NAVIGABLE_1907_2026-11-10.json
- Master_MK2_enriquecido_2026-11-10.json
- Nexo_Industrial_Master_Actualizado_2026-11-10.json
- Nexo_Industrial_Master_Actualizado_2026-11-10_KEY_VALUE.json
- Nexo_Industrial_Master_Actualizado_2026-11-10.xlsx
- Nexo_MAPS_patch_1907_2026-11-10.json
- nexo_companies_1907_georef.json
- master_prospeccion_Aurora_Sigma_MK2_2026_GEOREF_1907.xlsx
- companies.coordinates.audited.json
- companies.coordinates.audited.geojson
- coordinates.index.json
- GEOLOCATION_AUDIT.json
- Nexo-Geocoding-Checkpoint.zip
- Nexo-Industrial-coordinates-1907-audited.zip
- Nexo_19_geocoding_patch_2026-11-10.json
- Nexo_19_geocoding_patch_2026-11-10.csv
- Nexo_19_geocoding_review_2026-11-10.json
- SHA256SUMS.txt
- README_SNAPSHOT.md

## Límite conocido

El archivo temporal `gmap.json` del barrido que produjo el contador agregado **1,888 / 1,907** no quedó persistido ni en el runner ni en Library. Por lo tanto no se inventa ni se representa como si existiera.

El snapshot sí contiene todos los artefactos recuperables, el estado previo auditado, el master navegable y la revisión focalizada de las 19 cuentas.
