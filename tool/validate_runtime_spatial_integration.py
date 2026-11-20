#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "data/site_enrichment/2026-11-20_runtime_spatial_projection_integration.json"

MIGRATED = [
    ROOT / "lib/features/map/map_screen.dart",
    ROOT / "lib/features/map/ranking_service.dart",
    ROOT / "lib/features/companies/nearby_companies_screen.dart",
    ROOT / "lib/features/companies/company_detail_screen.dart",
]

FORBIDDEN = (
    "company.latitude",
    "company.longitude",
    "company.point",
    "company.canUseDistanceForRanking",
    "company.navigationEligible",
    "company.googleMapsDirectionsUri",
)

def fail(message):
    raise SystemExit(f"ERROR: {message}")

def main():
    audit = json.loads(AUDIT.read_text(encoding="utf-8"))
    if audit.get("contract") != "030":
        fail("invalid CONTRACT 030 audit")
    if audit.get("outreach_performed") is not False:
        fail("CONTRACT 030 performs no outreach")

    expected = audit.get("expected_state", {})
    required = {
        "companies": 1907,
        "runtime_spatial_views": 1907,
        "map_visible_views": 1907,
        "nearby_ranking_eligible": 370,
        "navigation_eligible": 370,
        "non_site_runtime_views": 0,
    }
    for key, value in required.items():
        if expected.get(key) != value:
            fail(f"{key} mismatch")

    for path in MIGRATED:
        content = path.read_text(encoding="utf-8")
        for token in FORBIDDEN:
            if token in content:
                fail(f"legacy spatial authority token remains in {path.name}: {token}")

    company = (ROOT / "lib/features/companies/domain/company.dart").read_text(
        encoding="utf-8"
    )
    legacy_present = (
        "final double latitude" in company
        or "final double longitude" in company
        or "nearbyRankingEligible" in company
        or "navigationEligible" in company
    )
    if legacy_present and "Deprecated compatibility field" not in company:
        fail("legacy Company spatial fields are not marked as deprecated compatibility")

    state = "legacy fields deprecated" if legacy_present else "legacy fields removed"
    print(
        "Runtime spatial integration OK: migrated consumers use runtime authority; "
        f"1,907 views / 370 nearby / 370 navigation expected; {state}."
    )

if __name__ == "__main__":
    main()
