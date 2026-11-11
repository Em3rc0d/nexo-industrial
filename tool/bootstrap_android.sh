#!/usr/bin/env bash
set -euo pipefail

export CI=true
export BOT=true
export FLUTTER_SUPPRESS_ANALYTICS=true

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
GENERATED="$TMP_DIR/nexo_generated"
PACKAGE_ID="pe.nexoindustrial.app"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

cd "$ROOT"

python3 tool/validate_dataset.py

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter no está instalado o no está en PATH." >&2
  exit 1
fi

flutter --version

flutter create \
  --platforms=android \
  --org=pe.nexoindustrial \
  --project-name=nexo_industrial \
  "$GENERATED"

rm -rf "$ROOT/android"
cp -R "$GENERATED/android" "$ROOT/android"

python3 - "$ROOT" "$PACKAGE_ID" <<'PY'
from pathlib import Path
import re
import shutil
import sys

root = Path(sys.argv[1])
package_id = sys.argv[2]
android = root / "android"

manifest = android / "app/src/main/AndroidManifest.xml"
text = manifest.read_text()

permissions = """    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
"""

marker = '<manifest xmlns:android="http://schemas.android.com/apk/res/android">'
if "android.permission.INTERNET" not in text:
    text = text.replace(marker, marker + "\n" + permissions)
else:
    missing = []
    if "ACCESS_COARSE_LOCATION" not in text:
        missing.append('    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>')
    if "ACCESS_FINE_LOCATION" not in text:
        missing.append('    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>')
    if missing:
        text = text.replace(marker, marker + "\n" + "\n".join(missing) + "\n")

text = re.sub(r'android:label="[^"]*"', 'android:label="Nexo Industrial"', text)
text = re.sub(r'android:icon="[^"]*"', 'android:icon="@drawable/ic_launcher"', text)
if "android:roundIcon=" in text:
    text = re.sub(
        r'android:roundIcon="[^"]*"',
        'android:roundIcon="@drawable/ic_launcher"',
        text,
    )

manifest.write_text(text)

for gradle_name in ("build.gradle.kts", "build.gradle"):
    gradle = android / "app" / gradle_name
    if not gradle.exists():
        continue

    g = gradle.read_text()
    g = re.sub(
        r'namespace\s*=\s*"[^"]+"',
        f'namespace = "{package_id}"',
        g,
    )
    g = re.sub(
        r'applicationId\s*=\s*"[^"]+"',
        f'applicationId = "{package_id}"',
        g,
    )
    g = re.sub(
        r'applicationId\s+"[^"]+"',
        f'applicationId "{package_id}"',
        g,
    )
    gradle.write_text(g)

main_activities = list((android / "app/src/main").rglob("MainActivity.kt"))
if not main_activities:
    raise SystemExit("No se encontró MainActivity.kt")

main_activity = main_activities[0]
main_text = main_activity.read_text()
main_text = re.sub(r'^package\s+[^\n]+', f'package {package_id}', main_text, flags=re.M)

target_dir = android / "app/src/main/kotlin" / Path(*package_id.split("."))
target_dir.mkdir(parents=True, exist_ok=True)
target = target_dir / "MainActivity.kt"
target.write_text(main_text)

if main_activity.resolve() != target.resolve():
    main_activity.unlink()

drawable = android / "app/src/main/res/drawable"
drawable.mkdir(parents=True, exist_ok=True)
(drawable / "ic_launcher.xml").write_text("""<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="108"
    android:viewportHeight="108">
    <path
        android:fillColor="#0E2A47"
        android:pathData="M14,2 H94 C100.6,2 106,7.4 106,14 V94 C106,100.6 100.6,106 94,106 H14 C7.4,106 2,100.6 2,94 V14 C2,7.4 7.4,2 14,2 Z" />
    <path
        android:fillColor="#16B8A6"
        android:pathData="M27,26 H40 V82 H27 Z" />
    <path
        android:fillColor="#16B8A6"
        android:pathData="M68,26 H81 V82 H68 Z" />
    <path
        android:fillColor="#16B8A6"
        android:pathData="M40,26 L68,64 V82 L40,44 Z" />
    <path
        android:fillColor="#F59E42"
        android:pathData="M83,22 A7,7 0,1 1,82.9,22 Z" />
</vector>
""")

# Remove now-empty package folders created by flutter when possible.
for parent in list(main_activity.parents):
    if parent == android / "app/src/main/kotlin":
        break
    try:
        parent.rmdir()
    except OSError:
        break
PY

flutter pub get
flutter analyze
flutter test

echo
echo "Android listo:"
echo "  app: Nexo Industrial"
echo "  package: pe.nexoindustrial.app"
echo "  version: 1.0.0+3"
echo
echo "Compila release con:"
echo "  flutter build apk --release"
