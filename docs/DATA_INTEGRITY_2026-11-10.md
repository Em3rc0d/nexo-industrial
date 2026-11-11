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

## Verificación Flutter ejecutada

Se instaló Flutter **3.47.9 stable** con Dart **3.13.7**, desde el archivo oficial cuyo SHA-256 es `25ed8c3c29d51a7353f2a944310b478af8214920639524b19c50a19e6c044c5a`. Las dependencias se resolvieron sin modificar `pubspec.lock`.

Los fixtures de dos pruebas antiguas no proporcionaban los campos obligatorios `commercial`, `fiscalAddress` y `verifiedHqAddress`; se corrigieron. No se modificó el constructor para ocultar esos errores.

Comandos ejecutados con `CI=true BOT=true FLUTTER_SUPPRESS_ANALYTICS=true`:

- `flutter analyze --no-pub`: **sin incidencias**.
- `flutter test --no-pub`: **7/7 pruebas aprobadas**. Incluye carga del repositorio real de assets, 1,907 RUC únicos, coordenadas válidas, datos comerciales y URLs de navegación/búsqueda para cada cuenta; además de ranking y ambos modos Maps.
- `python3 tool/test_geocode_verified.py`: **11/11 pruebas aprobadas**.
- Comprobación adicional: las 1,907 URLs Maps del master restaurado tienen estructura HTTPS, host, api y query válidos.

Los scripts de build ya activaban CI/BOT; ahora también desactivan explícitamente la telemetría. El primer arranque sin CI fue bloqueado por la consulta automática de detección de Azure. Se revisó `bot_detector.dart` del SDK y se usó el modo CI que evita esa consulta.

No se compiló ni certificó una APK en esta verificación, no se probó en un dispositivo Android y no se verificó que Google Maps resuelva físicamente cada consulta. Los tests no acreditan nuevas coordenadas reales.
