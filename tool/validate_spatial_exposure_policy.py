#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "data/site_enrichment/2026-11-20_spatial_entity_map_ux_exposure_policy.json"
PROPERTY = ROOT / "assets/data/property.facility.overlay.json"

def fail(message):
    raise SystemExit(f"ERROR: {message}")

def main():
    audit = json.loads(AUDIT.read_text(encoding="utf-8"))
    if audit.get("contract") != "029":
        fail("invalid CONTRACT 029 audit")
    if audit.get("outreach_performed") is not False:
        fail("CONTRACT 029 performs no outreach")

    expected = audit.get("expected_state", {})
    required = {
        "unified_placements": 1908,
        "commercial_map_primary_site_markers": 1907,
        "commercial_map_non_site_markers": 0,
        "nearby_ranking_exposed_sites": 370,
        "navigation_exposed_sites": 370,
        "non_site_commercial_exposure": 0,
    }
    for key, value in required.items():
        if expected.get(key) != value:
            fail(f"{key} mismatch")

    property_doc = json.loads(PROPERTY.read_text(encoding="utf-8"))
    placements = property_doc.get("placements", [])
    if len(placements) != 1:
        fail("expected one non-Site Placement")
    ana = placements[0]
    if ana.get("entity_type") != "asset":
        fail("ANA Placement must remain Asset-owned")
    if any(
        ana.get(field) is not False
        for field in (
            "map_display_eligible",
            "nearby_ranking_eligible",
            "navigation_eligible",
        )
    ):
        fail("ANA Placement permissions must remain fail-closed")

    ana_policy = audit.get("ana_well", {})
    for surface in ("commercial_map", "company_detail", "nearby_ranking", "navigation"):
        if ana_policy.get(surface) != "hidden":
            fail(f"ANA {surface} exposure must be hidden")

    print(
        "Spatial UX exposure policy OK: 1,907 Site map markers, "
        "370 nearby/navigation Sites, zero non-Site commercial exposure."
    )

if __name__ == "__main__":
    main()
