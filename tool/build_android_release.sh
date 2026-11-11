#!/usr/bin/env bash
set -euo pipefail

export CI=true
export BOT=true
export FLUTTER_SUPPRESS_ANALYTICS=true

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

python3 tool/validate_dataset.py

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter no está instalado o no está en PATH." >&2
  exit 1
fi

if [ ! -d android ]; then
  bash tool/bootstrap_android.sh
else
  flutter pub get
  flutter analyze
  flutter test
fi

if [ "${NEXO_LOW_MEMORY_BUILD:-0}" = "1" ]; then
  python3 tool/configure_android_low_memory.py
fi

flutter build apk --release

APK="$ROOT/build/app/outputs/flutter-apk/app-release.apk"

if [ ! -f "$APK" ]; then
  echo "No se encontró el APK esperado: $APK" >&2
  exit 1
fi

echo
echo "APK generado:"
echo "$APK"
ls -lh "$APK"
