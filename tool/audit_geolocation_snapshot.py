#!/usr/bin/env python3
"""Read-only, reproducible Nexo geolocation integrity audit (stdlib only)."""
import collections
import hashlib
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
SNAP = ROOT / "data/snapshots/2026-11-10"
DATA = ROOT / "assets/data"
PATCH = ROOT / "data/audits/Nexo_19_geocoding_patch_2026-11-10.json"
EXPECTED_ARCHIVE = "3506bf1adb25106c8b230c9492e37cf01c2b2d67f9be1f40df73452a5ea80e44"

def load(path):
    return json.loads(path.read_text(encoding="utf-8"))

def records(value):
    if isinstance(value, list):
        return value
    if isinstance(value, dict):
        for key in ("companies", "records", "data", "items"):
            if isinstance(value.get(key), list):
                return value[key]
    raise ValueError("Unsupported JSON collection structure")

def ruc(item):
    return str(item.get("ruc") or item.get("RUC") or "").strip()

def main():
    errors = []
    if "--restore" in sys.argv:
        subprocess.run(["bash", str(SNAP / "restore.sh")], check=True)
    archive = SNAP / "Nexo_Industrial_data_snapshot_2026-11-10.tar.gz"
    if archive.exists():
        digest = hashlib.sha256(archive.read_bytes()).hexdigest()
        if digest != EXPECTED_ARCHIVE:
            errors.append("Snapshot archive SHA-256 mismatch")
        else:
            print("PASS archive SHA-256")
    else:
        print("NOT TESTED archive restoration (run with --restore)")
    restored = SNAP / "restored"
    sums = restored / "SHA256SUMS.txt"
    if sums.exists():
        for line in sums.read_text().splitlines():
            digest, filename = line.split(maxsplit=1)
            file = restored / filename.strip("* ")
            if not file.is_file() or hashlib.sha256(file.read_bytes()).hexdigest() != digest:
                errors.append("Snapshot member missing or hash mismatch: " + filename)
        if not errors:
            print("PASS restored snapshot member hashes")
    else:
        print("NOT TESTED restored member hashes")
    companies = records(load(DATA / "companies.production.json"))
    overlay = records(load(DATA / "companies.geolocation.overlay.json"))
    company_ids = [ruc(x) for x in companies]
    overlay_ids = [ruc(x) for x in overlay]
    if len(companies) != 1907 or len(set(company_ids)) != 1907 or any(not x for x in company_ids):
        errors.append("Commercial dataset must contain exactly 1907 unique nonempty RUC")
    if len(overlay) != 1907 or len(set(overlay_ids)) != 1907 or set(company_ids) != set(overlay_ids):
        errors.append("Geolocation overlay must match exactly 1907 unique commercial RUC")
    direct = [x for x in overlay if x.get("navigation_eligible") is True]
    print(f"Commercial accounts: {len(companies)}; overlay: {len(overlay)}; direct navigation: {len(direct)}; textual fallback: {len(overlay)-len(direct)}")
    for x in direct:
        lat, lon = x.get("latitude"), x.get("longitude")
        if not (isinstance(lat, (int,float)) and isinstance(lon, (int,float)) and -90 <= lat <= 90 and -180 <= lon <= 180):
            errors.append("Invalid direct navigation coordinate for RUC " + ruc(x))
    patch = load(PATCH)
    rows = patch["records"]
    promoted = [x for x in rows if x["resolution_2026_11_10"].get("promote_direct_coordinate")]
    fallback = [x for x in rows if not x["resolution_2026_11_10"].get("promote_direct_coordinate")]
    if len(rows) != 19 or len(promoted) != 7 or len(fallback) != 12:
        errors.append("Patch must have 19 records: 7 promotions and 12 fallback")
    if len({ruc(x) for x in rows}) != len(rows):
        errors.append("Patch contains duplicate RUC")
    print(f"Patch: {len(promoted)} promotions, {len(fallback)} address queries")
    print("NOTE: 1895/1907 is NOT certified unless 1895 defensible direct coordinates exist in the production overlay.")
    if errors:
        for e in errors:
            print("FAIL:", e)
        return 1
    print("PASS structural checks; this does not validate real-world coordinate accuracy.")
    return 0

if __name__ == "__main__":
    sys.exit(main())
