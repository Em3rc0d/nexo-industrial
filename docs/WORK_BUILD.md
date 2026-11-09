# Construcción Android local

## Requisitos

- Flutter estable compatible con Dart 3.12+.
- Android SDK.
- JDK con `javac`.

## Generar Android

El directorio `android/` se genera localmente para evitar versionar artefactos de plataforma que Flutter puede reconstruir:

```bash
bash tool/bootstrap_android.sh
```

El script:

- genera Android con Flutter;
- fija nombre visible “Nexo Industrial”;
- configura permisos de Internet y ubicación;
- fija package id `pe.nexoindustrial.app`;
- ejecuta `flutter pub get`, `flutter analyze` y `flutter test`.

## Release

```bash
flutter build apk --release
```

Salida:

```
build/app/outputs/flutter-apk/app-release.apk
```

## Regla

No se usa GitHub Actions para compilar el APK. El build final debe realizarse en un entorno local con Flutter + Android SDK disponibles.
