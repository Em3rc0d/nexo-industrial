# Nexo Industrial — handoff MVP 1.0

## Estado

- Flutter local-first.
- Versión `1.0.0+3`.
- 1,907 cuentas / 1,907 RUC.
- 1,907/1,907 con coordenadas.
- 370 con navegación directa.
- Overlay geográfico auditado separado del dataset comercial.
- Fallback gratuito a Google Maps URLs para ubicaciones aproximadas.
- Actividad SQLite con resultado, nota, estado, siguiente paso y seguimiento.
- Filtros comerciales ligeros.
- Sin backend obligatorio.

## Flujo

Mapa → oportunidad → ficha → contacto/visita → registrar resultado → siguiente paso.

## Build

```bash
bash tool/bootstrap_android.sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

No usar GitHub Actions para compilar APK.

## Validaciones antes de distribuir

- permisos de ubicación aceptados/denegados;
- seguimiento al desplazarse;
- búsqueda por empresa/RUC;
- clustering;
- filtros;
- persistencia SQLite tras reinicio;
- migración de BD desde versión 1;
- navegación exacta;
- fallback “Buscar en Maps”;
- rendimiento con 1,907 cuentas.
