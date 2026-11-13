# Release checklist — Nexo Industrial 1.0.0

## Datos
- [x] 1,907 cuentas.
- [x] 1,907 RUC únicos.
- [x] 100% con coordenadas.
- [x] Overlay geográfico separado del dataset comercial.
- [x] 370 cuentas con navegación directa.
- [x] Validación offline en `tool/validate_dataset.py`.
- [x] Google Maps fallback para ubicaciones no navegables.

## Producto
- [x] Mapa con clustering.
- [x] Seguimiento de ubicación.
- [x] Reintento de ubicación.
- [x] Búsqueda por cuenta/RUC.
- [x] Filtros comerciales ligeros.
- [x] Ranking sensible a calidad geográfica.
- [x] Ficha comercial.
- [x] Registro de visita/llamada/información.
- [x] Resultado, nota, estado y siguiente paso.
- [x] Fecha opcional de seguimiento.
- [x] SQLite con migración de esquema v1 → v2.

## Android
- [x] Nombre final: Nexo Industrial.
- [x] Package id objetivo: `pe.nexoindustrial.app`.
- [x] Ícono fuente y VectorDrawable definidos.
- [x] Permisos de Internet/ubicación en bootstrap.
- [x] Script local de release.
- [ ] Ejecutar `flutter analyze` en un entorno con Flutter.
- [ ] Ejecutar `flutter test`.
- [ ] Ejecutar `flutter build apk --release`.
- [ ] Smoke test en dispositivo Android real.

## Regla de release

No etiquetar/distribuir 1.0.0 como APK final hasta que los cuatro checks pendientes de Android estén en verde.

No usar GitHub Actions para compilar el APK.

## Estabilización 13/11/2026

- [x] Reejecutadas auditorías Python de dataset y parche de contactos.
- [x] Bootstrap protege configuración Android existente.
- [x] Añadido respaldo/restauración JSON manual en Actividad (código).
- [ ] Ejecutar tests del respaldo, transacciones y migraciones en Flutter/SQLite.
- [ ] Verificar copia externa y restauración en Android real.
- [ ] Recuperar certificado de firma anterior y comprobar actualización sin pérdida.

Detalle y límites: `docs/STABILIZATION_2026-11-13.md`.
