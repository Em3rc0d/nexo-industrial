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

## Perfil opcional para entornos con poca memoria

```bash
NEXO_LOW_MEMORY_BUILD=1 bash tool/build_android_release.sh
```

Aplica un heap Gradle de 768 MiB, un worker, Kotlin in-process y sin daemon persistente. Desactiva el lint nativo de release y el shrinking Java/recursos para reducir consumo. Mantiene la compilación Flutter release/AOT, el análisis Flutter y sus pruebas. Para volver al perfil estándar, regenerar `android/` con `tool/bootstrap_android.sh`. Este perfil se utilizó para el APK 1.0.1+4.

El template Android actual firma con la clave debug: es una APK para instalación y pruebas, no una publicación en Play Store. La firma no garantiza compatibilidad de actualización con APK previas firmadas en otro entorno.
