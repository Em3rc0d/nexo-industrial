#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
OUT="Nexo_Industrial_data_snapshot_2026-11-10.tar.gz"
cat archive/Nexo_Industrial_data_snapshot_2026-11-10.tar.gz.b64.part-*.b64 | base64 --decode > "$OUT"
echo "3506bf1adb25106c8b230c9492e37cf01c2b2d67f9be1f40df73452a5ea80e44  $OUT" | sha256sum -c -
rm -rf restored
mkdir -p restored
tar -xzf "$OUT" -C restored
echo "Snapshot restaurado en: $(pwd)/restored"
