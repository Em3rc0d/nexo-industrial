# Nexo Industrial

**Radar comercial geográfico** para encontrar, entender y activar oportunidades industriales en campo.

La aplicación abre en el mapa y responde:

> Estoy aquí. ¿Qué empresas cercanas vale la pena visitar o contactar y por qué?

## MVP implementado

- **Mapa / Home** con ubicación, búsqueda y seguimiento.
- **Clustering** para evitar saturar la pantalla con el dataset completo.
- **Oportunidades destacadas** fuera del cluster cuando son las mejores candidatas relativas.
- **Buscar en esta zona** al explorar manualmente el mapa.
- **Panel de oportunidades cercanas** limitado y accionable.
- **Ficha comercial**: por qué interesa, qué ofrecer, con quién hablar y qué hacer.
- **Cuentas**: búsqueda manual por empresa/RUC.
- **Actividad**: historial local SQLite que nace solo de gestiones registradas.
- **Navegación externa** mediante Maps URL; no se usa Places/Search para descubrir prospectos.

## Principios

1. El dataset maestro propio es la fuente canónica.
2. El mapa solo visualiza/ubica cuentas.
3. No se inventan contactos, coordenadas ni evidencia.
4. Scores internos ordenan la experiencia, pero no se muestran al vendedor.
5. Un domicilio fiscal no se presenta como central confirmada.
6. La app debe seguir siendo útil sin backend obligatorio.

## Stack

- Flutter 3.47+ / Dart 3.12+
- flutter_map 8.3.2
- flutter_map_marker_cluster 8.2.2
- geolocator 14.1.2
- sqflite 2.4.5
- url_launcher 6.3.3

## Datos

El repositorio incluye solo datos de demostración en:

```
assets/data/companies.demo.json
```

El dataset real debe exportarse al contrato de `docs/DATA_CONTRACT.md`.

## Construir Android

Si todavía no existe `android/`:

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

Salida esperada:

```
build/app/outputs/flutter-apk/app-release.apk
```

No se usan GitHub Actions para compilar APK.

## Documentación

- `docs/PRODUCT.md`
- `docs/UX.md`
- `docs/ARCHITECTURE.md`
- `docs/DATA_CONTRACT.md`
- `docs/WORK_BUILD.md`
