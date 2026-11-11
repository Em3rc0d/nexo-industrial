# Integridad de datos — 10 de noviembre de 2026

## Reparación

El repositorio declaraba y cargaba obligatoriamente `assets/data/companies.commercial.overlay.json.gz`, pero no contenía el archivo. Se reconstruyó desde `Master_MK2_enriquecido_2026-11-10.json` del snapshot restaurado, sin inventar contactos ni promover coordenadas.

- Master fuente SHA-256: `859cbf6e373fb0446a927fa3daf9c0d21fd8acbc185e9d115c457c8a87e98946`.
- Asset recuperado SHA-256: `892e325f3e1bc0bd05f87d03594b1a242c50c0132e9f5866fe238d2aae43ad37`.
- 1,907 registros comerciales, con RUC únicos e idénticos al conjunto productivo.
- Recuperación determinista: `python3 tool/recover_commercial_overlay.py`, después de restaurar el snapshot.

La auditoría buscaba `SHA256SUMS.txt` en el directorio padre del contenido extraído y omitía comprobar los miembros. Ahora usa la carpeta real y falla si faltan el archivo comprimido o sus hashes restaurados. También comprueba el overlay comercial, domicilios fiscales y pertenencia de los RUC del parche a producción.

`tool/validate_dataset.py`, ejecutado antes del build Android, comprueba los assets declarados en pubspec, cobertura comercial y domicilios para búsqueda.

## Evidencia ejecutada

- `python3 tool/audit_geolocation_snapshot.py --restore`: correcto; archivo comprimido y 18 miembros con SHA-256 válido.
- `python3 tool/validate_dataset.py`: correcto.
- Recuperación comercial repetida: bytes idénticos.
- Eliminación temporal del asset comercial: la validación falla; archivo restaurado tras la prueba.
- Alteración temporal de un miembro restaurado: la auditoría falla; archivo restaurado tras la prueba.
- Dos ZIP internos: CRC íntegro.
- `git diff --check`: correcto.

## Alcance real

Producción mantiene **370** coordenadas habilitadas para navegación directa y **1,537** búsquedas por dirección. Las 1,907 cuentas tienen domicilio fiscal. El parche de 19 contiene 7 promociones propuestas y 12 fallbacks; las propuestas no se aplicaron en esta reparación. El resultado histórico de 1,895 coordenadas no queda certificado.

La prueba Flutter de producción se amplió para cubrir la presencia de información comercial y la construcción de URLs de navegación/búsqueda para las 1,907 cuentas. No se ejecutó: este entorno no tiene Flutter/Dart instalado. No se certifica una APK ni se verificó que Google Maps resuelva físicamente cada consulta.
