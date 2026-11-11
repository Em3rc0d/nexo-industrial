# Nexo Industrial 1.0.2+5 — cobertura del mapa

## Hallazgo

Se comparó la APK 1.0.1+4 con los assets del commit remoto `3342b5d96e2bec1e156a44b82c27a13acccf21b0`, main al iniciar esta revisión. Los tres archivos coincidían byte a byte. La APK contenía 1,907 cuentas: 113 de la provincia del Callao, 46 de Lurín y 30 de Villa El Salvador. Tamaño comprimido del JSON principal en esa APK: 305,350 bytes frente a 3,327,279 bytes descomprimidos. El tamaño global de APK no acredita frescura o completitud de los datos.

El mapa filtraba por distancia al ancla, usaba un radio máximo de 24 km y recortaba los resultados a 90 cuentas ordenadas comercialmente. El ancla no cambiaba al arrastrar hasta tocar un botón superpuesto al encabezado. La búsqueda tampoco incluía distrito/provincia. Eso ocultaba cuentas incluidas en los assets.

## Corrección

- Selección por límites de la cámara, actualizada al desplazar o cambiar zoom; sin recorte top-90 ni radio fijo.
- El ranking ordena las cuentas presentes en el área, sin excluir las referencias aproximadas por su calidad.
- Búsqueda global por nombre, RUC, sector, actividad, dirección, distrito, provincia y departamento; tolera tildes. El mapa encuadra las coincidencias automáticamente.
- Mismo criterio textual en la pestaña Cuentas.
- Encabezado fuera de la superficie del mapa y contador de cuentas en zona frente a total del dataset; desaparece el botón superpuesto.
- Todos los marcadores de empresas participan en clustering, incluidos los que antes eran tres pines naranja separados.
- Título de lista/panel referido a la zona; fondo opaco bajo la atribución OSM.

## Verificación

- `flutter analyze --no-pub`: sin incidencias.
- `flutter test --no-pub`: **9/9 aprobadas**.
- Nuevas regresiones con dataset productivo: el encuadre nacional devuelve las 1,907 cuentas; el encuadre Callao conserva sus 113; encuadres del sur conservan Lurín y Villa El Salvador; búsqueda global por Callao y Lurín/Villa El Salvador, incluidas ubicaciones aproximadas.
- Build release local, mismo perfil de memoria reducida de 1.0.1+4: sin lint nativo de release ni shrinking Java/recursos, con firma Android Debug. No se usó GitHub Actions.
- Firma APK y alineación ZIP de 16 KB aprobadas. Package `pe.nexoindustrial.app`, version name `1.0.2`, version code `5`.
- CRC del APK y tres assets productivos byte a byte idénticos al repositorio: aprobados.
- Archivo: `Nexo-Industrial-1.0.2-build5.apk`; **58,062,361 bytes**.
- SHA-256: `130adf3347e2f91b514cdf94c1a7e1a296055408c3f26064bef8a4489e7c604a`.

## Límites

El master sigue en 370 coordenadas habilitadas para navegación directa y 1,537 búsquedas por dirección. Las referencias distritales/calle no se han promovido a ubicación exacta. Esta corrección permite descubrir las cuentas existentes; no reconstruye el barrido histórico no persistido.

Las pruebas cubren selección, búsqueda y carga de assets reales. No hubo instalación ni validación visual de esta versión en teléfono o emulador. Las capturas del usuario corresponden a la versión anterior. Las pruebas de permisos, arrastre, zoom y disposición visual de la nueva APK quedan pendientes en dispositivo.
