#!/usr/bin/env python3
import json
import math
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/data/companies.production.json"
OVERLAY = ROOT / "assets/data/companies.geolocation.overlay.json"

EXPECTED_TOTAL = 1907
EXPECTED_QUALITY = {
    "exact_address": 334,
    "address_reference": 36,
    "interpolated_address": 137,
    "street_reference": 551,
    "district_reference": 849,
}


def main() -> None:
    base = json.loads(BASE.read_text(encoding="utf-8"))
    overlay = json.loads(OVERLAY.read_text(encoding="utf-8"))

    assert len(base) == EXPECTED_TOTAL, f"base: {len(base)} != {EXPECTED_TOTAL}"
    assert len(overlay) == EXPECTED_TOTAL, (
        f"overlay: {len(overlay)} != {EXPECTED_TOTAL}"
    )

    base_rucs = [str(item["ruc"]) for item in base]
    overlay_rucs = [str(item["ruc"]) for item in overlay]

    assert len(set(base_rucs)) == EXPECTED_TOTAL, "RUC duplicado en base"
    assert len(set(overlay_rucs)) == EXPECTED_TOTAL, "RUC duplicado en overlay"
    assert set(base_rucs) == set(overlay_rucs), "RUCs base/overlay no coinciden"

    quality = Counter()
    navigation = 0

    for item in overlay:
        lat = item.get("latitude")
        lon = item.get("longitude")
        assert isinstance(lat, (int, float)) and math.isfinite(lat)
        assert isinstance(lon, (int, float)) and math.isfinite(lon)
        assert -90 <= lat <= 90
        assert -180 <= lon <= 180

        q = item.get("location_quality")
        assert q in EXPECTED_QUALITY, f"location_quality inválido: {q}"
        quality[q] += 1

        if item.get("navigation_eligible") is True:
            navigation += 1
            assert q in {"exact_address", "address_reference"}, (
                f"Navegación habilitada con calidad no apta: {q}"
            )
            assert item.get("nearby_ranking_eligible") is True

    assert dict(quality) == EXPECTED_QUALITY, (
        f"Conteos de calidad inesperados: {dict(quality)}"
    )
    assert navigation == 370, f"navigation_eligible: {navigation} != 370"

    print("Dataset OK")
    print(f"  cuentas: {EXPECTED_TOTAL}")
    print("  cobertura coordenadas: 100%")
    print(f"  navegación directa: {navigation}")
    for key, value in EXPECTED_QUALITY.items():
        print(f"  {key}: {value}")


if __name__ == "__main__":
    main()
