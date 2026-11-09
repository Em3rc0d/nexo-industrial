# Handoff para ChatGPT Work

Este archivo define cómo continuar desde el repositorio sin reinterpretar el producto.

## Producto que debe preservarse

Nexo Industrial es un **radar comercial geográfico**.

Flujo principal:

```
Mapa → oportunidad cercana → ficha comercial → contacto/visita → registro de gestión
```

No convertir el MVP en una agenda automática ni en un CRM genérico.

## Implementado en main

### Home / Mapa
- apertura directa en Mapa;
- ubicación actual cuando el usuario concede permiso;
- fallback visual cuando la ubicación no está disponible;
- búsqueda por empresa/RUC/actividad;
- ranking interno por potencial, cercanía y confianza de ubicación;
- radio dinámico según zoom;
- límite de candidatos renderizados;
- clustering;
- top 3 oportunidades destacadas con pin naranja;
- panel inferior con oportunidades cercanas;
- modo exploración;
- botón “Buscar en esta zona”;
- botón para volver a “Mi ubicación”.

### Ficha comercial
Orden UX:
1. por qué conviene contactar;
2. qué podría ofrecerse de Aurora/Sigma;
3. con quién hablar y cómo contactar;
4. qué pasó antes y qué toca hacer.

Incluye:
- calidad de ubicación;
- fuente y fecha;
- llamada solo si existe teléfono;
- navegación externa;
- registro explícito de visita, llamada o envío de información.

### Cuentas
- búsqueda manual del dataset;
- acceso a ficha comercial.

### Actividad
- SQLite local;
- empieza vacía;
- solo registra acciones del usuario;
- no genera tareas o agenda por sí sola.

## Datos

El repositorio usa exclusivamente:

`assets/data/companies.demo.json`

para poder probar UI sin publicar información comercial real.

Antes de una prueba real:
1. exportar el dataset maestro al contrato de `docs/DATA_CONTRACT.md`;
2. validar coordenadas;
3. excluir `uncertain` del mapa;
4. conservar provenance, fecha y estado de ubicación;
5. no inventar contactos.

## Construcción Android

Desde la raíz:

```bash
bash tool/bootstrap_android.sh
flutter build apk --release
```

El bootstrap:
- genera `android/` con el Flutter instalado;
- añade INTERNET;
- añade ACCESS_COARSE_LOCATION;
- añade ACCESS_FINE_LOCATION;
- ejecuta `flutter pub get`;
- ejecuta `flutter analyze`;
- ejecuta `flutter test`.

## Validación visual obligatoria

Antes de considerar el APK listo:
- probar teléfono pequeño y teléfono grande;
- confirmar que el bottom sheet no tapa por completo el mapa;
- confirmar que el header no ocupa demasiada altura;
- probar clusters con ~1,900 cuentas;
- verificar que los 3 pins destacados no destruyan el clustering;
- comprobar “Buscar en esta zona” al arrastrar;
- comprobar que el mapa no vuelva solo a la posición mientras se explora;
- probar permiso de ubicación denegado;
- probar Actividad tras reiniciar la app;
- probar llamada y navegación externa.

## Criterios de aceptación

- El usuario entiende qué hacer sin conocer scores internos.
- No aparecen 1,900 pins simultáneos.
- Las mejores oportunidades cercanas tienen mayor visibilidad.
- Toda recomendación comercial tiene explicación legible.
- Una dirección fiscal no se presenta como central confirmada.
- No se muestra un contacto inexistente.
- No se calcula distancia sobre coordenadas no confiables.
- El core funciona sin backend obligatorio.
- No se usa Google Places/Search para descubrir cuentas.

## Fuera del MVP

No implementar todavía:
- planificación automática del día;
- optimizador de rutas;
- seguimiento GPS en background;
- backend obligatorio;
- sincronización multiusuario;
- recomendaciones generativas sin evidencia;
- nuevos servicios de mapas pagos.

## APK

Salida esperada:

`build/app/outputs/flutter-apk/app-release.apk`

No configurar GitHub Actions para compilar el APK.
