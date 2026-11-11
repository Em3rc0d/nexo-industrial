# Nexo Industrial 1.0.1+4 — APK de prueba

Fecha: 10 de noviembre de 2026 (Lima).

## Artefacto compilado localmente

- Archivo: `Nexo-Industrial-1.0.1-build4.apk`.
- Tamaño: **58,062,521 bytes**.
- SHA-256: `88aa26320c1f88e6cc513d43564ab6fcb3a62ac14a73845b88c88f3a3a2bd893`.
- Package: `pe.nexoindustrial.app`.
- Label: `Nexo Industrial`.
- Version name: `1.0.1`; version code: `4`.
- Android mínimo: API 24 (Android 7.0); target/compile SDK: 36.
- ABI: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- Release/AOT, manifest no depurable, sin minificación Java ni shrinking de recursos.

## Firma

`apksigner verify --verbose --print-certs`: válida mediante APK Signature Scheme v2.

Certificado: **Android Debug**, RSA 2048.

SHA-256 del certificado: `798f3f24b8801e768243fa9326954e6069c5b22b897378c3f53261f331224d83`.

Es un build para instalación y pruebas. No constituye una publicación en Play Store ni garantiza actualización sobre una APK firmada con otra clave. No se debe desinstalar una app anterior con gestiones locales sin respaldarlas antes.

## Evidencia

- `flutter analyze`: sin incidencias durante bootstrap Android.
- `flutter test`: 7/7 aprobadas durante bootstrap Android.
- `python3 tool/test_geocode_verified.py`: 11/11 aprobadas en la verificación previa.
- Archivo ZIP/APK: CRC íntegro.
- `zipalign -c -P 16 4`: aprobado.
- `aapt dump badging`: package, version, label, SDK y ABI correctos; permisos INTERNET, ACCESS_FINE_LOCATION y ACCESS_COARSE_LOCATION presentes; no `application-debuggable`.
- Los tres assets productivos empaquetados son byte a byte idénticos a los archivos fuente.
- APK: 1,907 cuentas, overlays geográfico/comercial con el mismo conjunto de RUC únicos; 370 coordenadas aptas para navegación directa y 1,537 búsquedas por dirección.

## Entorno y reproducción

Flutter 3.47.9 / Dart 3.13.7; Temurin JDK 21.0.13+9; Android command-line tools 19; SDK 36 (más 35 para dependencias), Build Tools 36.0.0, NDK 28.2.13676358 y CMake 3.22.1. Gradle 9.3.1 y AGP 9.1.0 generados por Flutter.

Se utilizó el perfil `NEXO_LOW_MEMORY_BUILD=1` documentado en `WORK_BUILD.md`: Gradle 768 MiB, un worker, Kotlin in-process, sin daemon persistente ni lint nativo de release, sin shrinking Java/recursos. Los primeros intentos terminaron con desaparición del daemon; el perfil de memoria reducida terminó correctamente. No se utilizó GitHub Actions. Los ajustes de proxy y certificados pertenecen al entorno local y no se versionan.

El APK compila con datos del repositorio y el overlay comercial recuperado. No certifica las 1,895 coordenadas históricas no persistidas.

## Pendiente de prueba en Android

No se realizó instalación ni prueba interactiva en teléfono o emulador. Este entorno no dispone de dispositivo Android conectado ni de `/dev/kvm` para un emulador acelerado.

Validar en un teléfono: instalación/actualización compatible con firma, apertura y carga de cuentas, búsqueda y filtros, mapa online, permiso de ubicación concedido/denegado, ambos modos de Maps, teléfono, registro de gestiones y persistencia después de cerrar/reabrir. El acceso a datos sin red y los mensajes ante falta de conectividad también requieren prueba en dispositivo.
