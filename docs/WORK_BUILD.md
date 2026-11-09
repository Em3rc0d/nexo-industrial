# Construcción del APK con ChatGPT Work

## Requisitos

- Flutter estable con Dart 3.12+.
- Android SDK.
- JDK soportado por Flutter.

## Flujo

```bash
git clone https://github.com/Em3rc0d/nexo-industrial.git
cd nexo-industrial

bash tool/bootstrap_android.sh
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Salida:

```
build/app/outputs/flutter-apk/app-release.apk
```

## Bootstrap Android

El script genera un proyecto Android temporal usando el Flutter instalado, copia solo android/ y añade permisos de ubicación. El código Dart no se regenera.

## Antes de entregar

- sustituir dataset demo por export canónico;
- comprobar coordenadas y estados de ubicación;
- probar permiso de ubicación aceptado/denegado;
- probar “Buscar en esta zona”;
- probar clustering con dataset completo;
- probar persistencia de actividad tras reiniciar;
- verificar navegación externa;
- cerrar launcher icon final.

## No hacer

- no usar Google Places/Search para descubrir cuentas;
- no usar GitHub Actions para compilar APK;
- no subir keystores o claves.
