# Nexo Industrial: continuación en Work

## Estado verificable

- Flutter 3.47.9 / Dart 3.13.7; aplicación Android local-first.
- Versión 0.1.1+2.
- Asset real: `assets/data/companies.production.json`, 1,907 RUC únicos.
- 1,907 domicilios fiscales SUNAT (2026-11-09).
- 274 ubicaciones aptas para cercanía/navegación; 1,633 pendientes.
- Las pendientes no deben habilitar rutas ni distancias de visita.
- Las ubicaciones utilizables son domicilios fiscales, no sedes operativas verificadas.

## Construcción

Instalar Flutter, Android SDK y JDK completo (`javac` obligatorio).
Ejecutar `bash tool/bootstrap_android.sh` si falta Android; luego:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

En entornos automatizados, establecer `CI=true` y `BOT=true` para evitar la
sonda de metadatos Azure de Flutter. No acceder a metadatos de infraestructura.
En entornos de poca memoria, usar un trabajador Gradle, heap 768 MB y metaspace
768 MB. No subir proxies locales, `local.properties`, SDKs ni claves a GitHub.

## Datos

Consultar `GEOLOCATION.md` y `GEOLOCATION_RESULT.json`. Reusar caché de las
consultas puntuales; no repetir lotes Nominatim sin verificar su política.
Nunca promover un centroide por completar un contador. Resolver los pendientes
con evidencia adicional o confirmación en campo.

## Producto

Mapa → oportunidad → ficha → contacto/visita → registro explícito.
No generar agenda, llamadas ni gestiones automáticamente. No usar Google Places
para descubrir prospectos. No usar GitHub Actions para compilar el APK.
