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
