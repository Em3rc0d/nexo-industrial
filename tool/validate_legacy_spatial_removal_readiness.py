#!/usr/bin/env python3
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "data/site_enrichment/2026-11-20_legacy_spatial_dependency_audit.json"

PRODUCTION_FILES = [
    ROOT / "lib/app/nexo_app.dart",
    ROOT / "lib/features/home/home_shell.dart",
    ROOT / "lib/features/companies/companies_screen.dart",
    ROOT / "lib/features/companies/company_detail_screen.dart",
    ROOT / "lib/features/companies/nearby_companies_screen.dart",
    ROOT / "lib/features/companies/data/asset_company_repository.dart",
    ROOT / "lib/features/map/map_screen.dart",
    ROOT / "lib/features/map/ranking_service.dart",
]

FORBIDDEN = (
    "company.latitude",
    "company.longitude",
    "company.locationQuality",
    "company.locationConfidence",
    "company.nearbyRankingEligible",
    "company.navigationEligible",
    "company.hasMapCoordinates",
    "company.hasReliableCoordinates",
    "company.canUseDistanceForRanking",
    "company.googleMapsDirectionsUri",
    "company.googleMapsSearchUri",
)

def fail(message):
    raise SystemExit(f"ERROR: {message}")

def main():
    audit = json.loads(AUDIT.read_text(encoding="utf-8"))
    if audit.get("decision") != "GO_FOR_REMOVAL":
        fail("CONTRACT 031 is not GO_FOR_REMOVAL")
    if audit.get("production_authority_consumers") != 0:
        fail("production authority consumers remain")
    if audit.get("production_indirect_consumers") != 0:
        fail("indirect production consumers remain")
    if audit.get("serialization_blockers") != 0:
        fail("serialization blockers remain")

    for path in PRODUCTION_FILES:
        content = path.read_text(encoding="utf-8")
        for token in FORBIDDEN:
            if token in content:
                fail(f"legacy spatial dependency remains in {path.name}: {token}")

    company = (ROOT / "lib/features/companies/domain/company.dart").read_text(
        encoding="utf-8"
    )
    if "this.latitude = 0.0" not in company:
        fail("Company latitude is still required")
    if "this.navigationEligible = false" not in company:
        fail("Company navigation eligibility is still required")

    print(
        "Legacy spatial dependency audit OK: GO_FOR_REMOVAL; "
        "0 production authority consumers, 0 indirect consumers."
    )

if __name__ == "__main__":
    main()
