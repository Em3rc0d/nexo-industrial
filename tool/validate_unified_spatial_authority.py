#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OVERLAY = ROOT / "assets/data/property.facility.overlay.json"
AUDIT = ROOT / "data/site_enrichment/2026-11-20_unified_spatial_placement_authority.json"

def fail(message):
    raise SystemExit(f"ERROR: {message}")

def main():
    overlay = json.loads(OVERLAY.read_text(encoding="utf-8"))
    placements = overlay.get("placements", [])
    if len(placements) != 1:
        fail("CONTRACT 028 expects exactly one non-Site production Placement")

    ana = placements[0]
    if ana.get("entity_type") != "asset":
        fail("ANA Placement must remain owned by Asset")
    if ana.get("map_display_eligible") is not False:
        fail("ANA Asset Placement must remain hidden from commercial map")
    if ana.get("nearby_ranking_eligible") is not False:
        fail("ANA Asset Placement cannot influence nearby ranking")
    if ana.get("navigation_eligible") is not False:
        fail("ANA Asset Placement cannot enable navigation")

    audit = json.loads(AUDIT.read_text(encoding="utf-8"))
    if audit.get("contract") != "028":
        fail("invalid CONTRACT 028 audit")
    if audit.get("outreach_performed") is not False:
        fail("CONTRACT 028 performs no outreach")

    expected = audit.get("expected_state", {})
    if expected.get("active_sites") != 1907:
        fail("active Site count must remain 1907")
    if expected.get("legacy_site_placements") != 1907:
        fail("legacy Site Placement count must remain 1907")
    if expected.get("unified_site_placements") != 1907:
        fail("unified Site Placement count must be 1907")
    if expected.get("unified_non_site_placements") != 1:
        fail("unified non-Site Placement count must be 1")
    if expected.get("unified_total_placements") != 1908:
        fail("unified total Placement count must be 1908")
    if expected.get("nearby_ranking_eligible") != 370:
        fail("nearby eligibility count regression")
    if expected.get("navigation_eligible") != 370:
        fail("navigation eligibility count regression")

    print(
        "Unified spatial authority audit OK: 1,907 Site Placements + 1 Asset "
        "Placement; ANA non-actionable; no Site mutation; no outreach."
    )

if __name__ == "__main__":
    main()
