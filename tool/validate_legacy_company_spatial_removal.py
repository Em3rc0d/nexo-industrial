#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "data/site_enrichment/2026-11-20_legacy_company_spatial_field_removal.json"
COMPANY = ROOT / "lib/features/companies/domain/company.dart"
REPOSITORY = ROOT / "lib/features/companies/data/asset_company_repository.dart"

FORBIDDEN_COMPANY = (
    "final double latitude",
    "final double longitude",
    "LocationQuality",
    "LocationConfidence",
    "nearbyRankingEligible",
    "navigationEligible",
    "locationDistrict",
    "locationProvince",
    "locationDepartment",
    "hasMapCoordinates",
    "hasReliableCoordinates",
    "googleMapsSearchUri",
    "googleMapsDirectionsUri",
    "distanceEvidenceWeight",
    "json['geography']",
)

def fail(message):
    raise SystemExit(f"ERROR: {message}")

def main():
    audit = json.loads(AUDIT.read_text(encoding="utf-8"))
    if audit.get("contract") != "032":
        fail("invalid CONTRACT 032 audit")
    if audit.get("decision") != "REMOVAL_COMPLETE":
        fail("physical removal not complete")
    if audit.get("commercial_repository_geolocation_overlay_dependency") is not False:
        fail("commercial repository still depends on geolocation overlay")
    if audit.get("spatial_dataset_deleted") is not False:
        fail("spatial dataset must not be deleted")

    company = COMPANY.read_text(encoding="utf-8")
    for token in FORBIDDEN_COMPANY:
        if token in company:
            fail(f"legacy Company spatial token remains: {token}")

    repository = REPOSITORY.read_text(encoding="utf-8")
    for token in (
        "geolocationOverlayPath",
        "companies.geolocation.overlay.json",
        "overlayByRuc",
        "item['geography']",
    ):
        if token in repository:
            fail(f"commercial repository still reads spatial overlay: {token}")

    expected = audit.get("expected_state", {})
    if expected != {
        "companies": 1907,
        "runtime_spatial_views": 1907,
        "map_visible": 1907,
        "nearby_eligible": 370,
        "navigation_eligible": 370,
        "non_site_runtime_views": 0,
    }:
        fail("CONTRACT 032 expected-state drift")

    print(
        "Legacy Company spatial removal OK: Company is spatial-free; "
        "commercial repository no longer reads geolocation overlay; "
        "runtime authority remains Site/EntityPlacement."
    )

if __name__ == "__main__":
    main()
