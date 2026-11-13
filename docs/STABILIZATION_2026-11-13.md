# Estabilización y protección de historial — 13/11/2026

## Evidencia comprobada

`python3 tool/validate_dataset.py` y `python3 tool/validate_contact_patch.py`
terminan correctamente: 1,907 RUC únicos, 292 con teléfono, 176 con email,
299 con cualquiera, 304 incluyendo páginas/portales y 33 profesionales en
21 empresas. Navegación directa: 370. No se han investigado ni añadido
contactos en esta intervención.

## Respaldo manual implementado (pendiente de ejecución Flutter)

Actividad → Respaldar genera JSON versionado de todas las gestiones SQLite.
Se copia manualmente y debe guardarse en un archivo `.json` fuera de la app;
el portapapeles NO constituye un respaldo durable. No se comparte ni envía
automáticamente. Contiene notas comerciales: el usuario elige dónde conservarlo.

Actividad → Restaurar recibe ese JSON, valida todo el documento y muestra
el número de registros antes de la confirmación. La confirmación combina
registros dentro de una transacción SQLite, sin borrar ni sobrescribir
los existentes. Omite duplicados exactos de todos los campos de negocio,
independientemente del ID SQLite original. Una gestión idéntica en todos
sus campos se considera la misma. No se incluye el maestro empresarial,
que proviene del repositorio. No se verifica el RUC contra el catálogo al
restaurar: se conserva el historial incluso de cuentas retiradas.

Los respaldos de otras versiones se rechazan. Límite de importación:
20 millones de unidades de texto aproximadamente y 50,000 gestiones.
La copia manual no incorpora selector de archivos ni respaldo automático.

## Seguridad de preparación Android

El bootstrap ahora se detiene si Android ya existe, en vez de eliminarlo.
Ambos scripts ejecutan la auditoría de contactos antes de proceder.
Se conserva el package ID objetivo `pe.nexoindustrial.app`.

Esto NO resuelve la firma: antes de distribuir hay que identificar el
certificado de la APK ya instalada. No crear otra clave ni desinstalar la
app para actualizar sin respaldar. Una firma diferente impedirá actualizar
la instalación existente aunque coincida el package ID.

## Gates aún abiertos

- Flutter/Dart/Android SDK no encontrados en PATH en este entorno.
- Pruebas Dart de codec añadidas, aún no ejecutadas.
- Pendiente prueba SQLite real: restaurar, repetir sin duplicar y comprobar
  rollback ante fallo; migración v1 → v2 y actualización conservando gestiones.
- Pendiente análisis Flutter, build local y prueba del diálogo en pantalla pequeña.
- Pendiente probar exportar → guardar fuera → restaurar en otra instalación.
- Pendiente obtener y configurar la identidad de firma de instalación existente.
- Sin APK nueva y sin GitHub Actions.

MK1 y MK2 siguen abiertos hasta superar estas comprobaciones. No se ha
contactado a personas ni empresas.
