#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
GENERATED="$TMP_DIR/nexo_generated"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

cd "$ROOT"
flutter --version

flutter create   --platforms=android   --org=pe.nexoindustrial   --project-name=nexo_industrial   "$GENERATED"

rm -rf "$ROOT/android"
cp -R "$GENERATED/android" "$ROOT/android"

MANIFEST="$ROOT/android/app/src/main/AndroidManifest.xml"

python3 - "$MANIFEST" <<'PY'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

permissions = """    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
"""

if "android.permission.INTERNET" not in text:
    marker = "<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\">"
    text = text.replace(marker, marker + "\n" + permissions)
elif "ACCESS_FINE_LOCATION" not in text:
    marker = "<manifest xmlns:android=\"http://schemas.android.com/apk/res/android\">"
    location_permissions = """    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
"""
    text = text.replace(marker, marker + "\n" + location_permissions)

path.write_text(text)
PY

flutter pub get
flutter analyze
flutter test

echo "Android listo. Compila con: flutter build apk --release"
