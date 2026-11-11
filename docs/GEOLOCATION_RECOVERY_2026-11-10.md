# Recuperación de geolocalización — 10 de noviembre de 2026

## Estado

Nexo tiene **1,907 / 1,907 cuentas operativamente navegables**.

La revisión focalizada reconstruida sobre las 19 cuentas que habían quedado fuera del último barrido logró promover **7** casos adicionales a coordenadas numéricas defendibles y mantiene **12** mediante búsqueda textual de dirección.

Si el conjunto reconstruido de 19 coincide exactamente con el conjunto temporal del barrido anterior, el KPI de coordenadas directas sería **1,895 / 1,907 (99.37%)**.

## Advertencia de persistencia

El barrido temporal previo que produjo **1,888 / 1,907** coordenadas directas no quedó persistido como un artefacto completo ni fue versionado en Git. Por ello, **no debe afirmarse que el overlay productivo actual de Git contiene 1,895 coordenadas directas**.

El archivo productivo actualmente versionado sigue siendo:

`assets/data/companies.geolocation.overlay.json`

y corresponde al estado auditado anterior documentado en `docs/GEOLOCATION.md`.

## Artefactos de recuperación

- `data/audits/Nexo_19_geocoding_patch_2026-11-10.json`
- `data/audits/Nexo_19_geocoding_patch_2026-11-10.csv`

Estos archivos conservan la evidencia y las decisiones de precisión de la revisión focalizada.

## Política

No se promueven centroides, referencias de calle o puntos vecinos a ubicación exacta únicamente para completar un contador.

Para los casos sin coordenada directa suficientemente defendible, Nexo debe usar:

`razón social + domicilio fiscal SUNAT + distrito/provincia + Perú`

mediante Google Maps URL, sin Google Maps SDK ni Places API.

## Próximo paso de datos

Para que el overlay productivo represente el KPI 1,895/1,907, primero debe recuperarse o reconstruirse de forma reproducible el bloque de **1,518 coordenadas** que elevó el estado anterior de 370 a 1,888. Hasta entonces, los artefactos de auditoría y el overlay productivo deben mantenerse diferenciados.
