# Nexo Industrial

**Radar comercial geográfico** para encontrar, entender y activar oportunidades industriales en campo.

La aplicación responde:

> Estoy aquí. ¿Qué empresas cercanas vale la pena visitar o contactar, por qué y qué debería hacer después?

## MVP 1.0

- Mapa/Home con ubicación, búsqueda, seguimiento y “Buscar en esta zona”.
- Clustering para evitar saturación con 1,907 cuentas.
- Ranking que combina potencial comercial, distancia y calidad de evidencia geográfica.
- Ficha comercial con oportunidad, oferta Aurora/Sigma, contacto, ubicación y próxima acción.
- Búsqueda por empresa/RUC/sector/actividad.
- Filtros por sector, calidad de ubicación, gestión y prioridad alta.
- Historial local SQLite con resultado, nota, estado comercial, siguiente paso y fecha de seguimiento.
- Navegación externa por Google Maps URL cuando la dirección es precisa.
- Fallback “Buscar en Maps” cuando la ubicación es aproximada.
- Sin backend obligatorio y sin Google Places para descubrir prospectos.

## Datos

Fuente comercial canónica:

`assets/data/companies.production.json`

Overlay geográfico auditado:

`assets/data/companies.geolocation.overlay.json`

Estado del 9 de noviembre de 2026:

- **1,907/1,907 cuentas con coordenadas**.
- **334 exact_address**.
- **36 address_reference**.
- **137 interpolated_address**.
- **551 street_reference**.
- **849 district_reference**.
- **370 cuentas habilitadas para navegación directa**.

El 100% de cobertura geográfica no equivale a 100% de puertas exactas.

Snapshot completo de recuperación (masters, XLSX, checkpoints, auditorías y patches):

`data/snapshots/2026-11-10/MANIFEST.md`

## Stack

- Flutter 3.47+ / Dart 3.12+
- flutter_map 8.3.2
- flutter_map_marker_cluster 8.2.2
- geolocator 14.1.2
- latlong2 0.9.1
- sqflite 2.4.5
- url_launcher 6.3.3

## Android

El repositorio no versiona un proyecto Android generado. Para crearlo localmente:

```bash
bash tool/bootstrap_android.sh
```

Luego:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Salida:

```
build/app/outputs/flutter-apk/app-release.apk
```

No se usa GitHub Actions para compilar el APK.

## Documentación

- `docs/PRODUCT.md`
- `docs/UX.md`
- `docs/ARCHITECTURE.md`
- `docs/DATA_CONTRACT.md`
- `docs/GEOLOCATION.md`
- `docs/GEOLOCATION_RECOVERY_2026-11-10.md`
- `docs/WORK_BUILD.md`
- `docs/BRANDING.md`
- `docs/RELEASE_CHECKLIST.md`
- `CHANGELOG.md`

## Verificación reproducible de datos

```bash
python3 tool/validate_dataset.py
python3 tool/audit_geolocation_snapshot.py --restore
python3 tool/validate_contact_patch.py
```

La recuperación del asset comercial desde el master guardado está documentada en `docs/DATA_INTEGRITY_2026-11-10.md`. La validación de datos no sustituye `flutter analyze` y `flutter test` antes de compilar.

## Contactos — corte 11/11/2026

1,907 cuentas; 267 con teléfono, 157 con email y 270 con alguno de esos dos canales. Hay 2 cuentas adicionales con página/formulario revisado, sin teléfono/email promovido. Las 1,907 referencias históricas de representante/cargo no equivalen a contactos directos.

Primer bloque: 24 cuentas prioritarias de Callao/Lima Sur revisadas; 13 nuevos canales por cuenta, 2 páginas empresariales y 9 casos que requieren corroboración. Fuentes, fechas y propósito se conservan en `data/contact_enrichment/2026-11-11_callao_sur.json`; el progreso y la cola de 1,637 RUC pendientes están en el mismo directorio. Detalle en `docs/CONTACT_ENRICHMENT_2026-11-11.md`.

Estos cambios corresponden al código/datos de 1.0.4+7. La APK 1.0.3+6 entregada anteriormente no incluye este lote.

## Personas clave — piloto 11/11/2026 (código, APK pendiente)

La ficha de veintiuna empresas del master incorpora **33 referencias profesionales públicas** de compras, logística y abastecimiento. La fuente de producción es `data/people_enrichment/2026-11-11_mining_people.json`, enlazada por RUC. Incluye LinkedIn, evidencia, estado temporal y advertencias cuando no se confirma el cargo vigente. Ninguna identidad se suma como teléfono/email directo. Hay **0 números individuales verificados**; se conserva **1 correo laboral público dirigido a proveedores** con vigencia pendiente de reconfirmación. No se añade al contador de contacto directo de la empresa.

El campo `workers_sunat` del perfil comercial y cualquier recuento de perfiles de LinkedIn representan conceptos distintos; un perfil no acredita nómina vigente ni teléfono.

La investigación aceptada ya se incorpora al código mediante un parche comercial de 33 RUC. El asset comprimido sigue con 270 empresas con teléfono/email, pero el cargador Flutter aplica un parche que eleva la expectativa de cobertura a **299**. No es una APK nueva ni una ejecución comprobada de Flutter.

Se documenta una investigación pasiva adicional de CMH, Catalina Huanca, Raura, SFP, Las Bambas y Ares sin enviar emails, mensajes, conexiones, llamadas ni formularios. El sitio oficial de CMH publica portal eBIZ de proveedores: `https://ebiz.pe/proveedores-cmh/`; su teléfono/email quedaron como descubrimiento staged, no como aumento comprobado de cobertura productiva.

Ver `docs/PEOPLE_ENRICHMENT_2026-11-11.md` y `docs/CONTACT_ENRICHMENT_2026-11-11.md`. Se requiere `flutter analyze`, `flutter test` y compilación local antes de otra APK.

## Contactos integrados en fuente — 11/11/2026 (APK pendiente)

Hay 9 lotes de investigación pública guardados en `data/contact_enrichment/`, incluidos los lotes de Tecnomin Data, Explo Drilling, SEA, Los Quenuales, OREX, TPE Paita, Paltarumi, Construplan, Mincotrall, EVS y South American Drilling, con AKD deduplicado por ya constar en la cobertura base. Se revisaron **77 RUC**; **42** ganaron canales telefónicos o emails públicos, **5** aportaron únicamente página/portal oficial; **2** (CMH y AK Drilling) ya tenían ambos canales y 28 quedaron sin nuevo canal promocionable.

**El asset comercial comprimido conserva 267 RUC con teléfono, 157 con email y 270 con cualquiera.** El código Flutter ahora aplica `assets/data/companies.contact.patch.json` (33 RUC) durante la carga, con expectativa de **292** con teléfono, **176** con email, **299** con alguno de ambos y **304** incluyendo páginas/portales; restarían **1,608** RUC sin teléfono/email. El manifiesto diferencia ambos cortes. **Sin Flutter ejecutado ni APK nueva**.

Detalle, evidencias, política de exclusiones y gate de reconstrucción: `docs/CONTACT_ENRICHMENT_2026-11-11.md` y `data/contact_enrichment/staged_status_2026-11-11.json`. No se ha llamado, escrito, enviado formulario ni solicitado conexión a ningún prospecto.
