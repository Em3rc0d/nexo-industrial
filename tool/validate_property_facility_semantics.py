#!/usr/bin/env python3
import json
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
OVERLAY = ROOT / "assets/data/property.facility.overlay.json"
AUDIT_026 = ROOT / "data/site_enrichment/2026-11-19_property_relationship_resolution.json"
AUDIT_027 = ROOT / "data/site_enrichment/2026-11-19_property_facility_semantic_separation.json"

def fail(message):
    raise SystemExit(f"ERROR: {message}")

def check_urls(rows):
    for row in rows:
        for item in row.get("evidence", []):
            locator = item.get("locator", "")
            if item.get("source_type") == "url":
                parsed = urlparse(locator)
                if parsed.scheme != "https" or not parsed.netloc:
                    fail(f"public evidence must use HTTPS: {locator}")

def main():
    doc = json.loads(OVERLAY.read_text(encoding="utf-8"))
    if doc.get("format") != "nexo-industrial-property-facility-overlay":
        fail("invalid overlay format")
    if doc.get("version") != 1:
        fail("unsupported overlay version")

    properties = doc.get("properties", [])
    facilities = doc.get("facilities", [])
    assets = doc.get("assets", [])
    placements = doc.get("placements", [])
    relationships = doc.get("property_site_relationships", [])

    if len(properties) != 1 or len(facilities) != 1 or len(assets) != 1:
        fail("CONTRACT 027 baseline expects 1 Property, 1 Facility and 1 Asset")
    if len(placements) != 1 or len(relationships) != 1:
        fail("CONTRACT 027 baseline expects 1 typed Placement and 1 relationship")

    prop = properties[0]
    fac = facilities[0]
    asset = assets[0]
    placement = placements[0]
    rel = relationships[0]

    if prop.get("id") != "property:20501523837:mz-b-lote-1":
        fail("unexpected Property id")
    if prop.get("tenure") != "leased":
        fail("Explomin Lote 1 tenure must remain leased from ANA evidence")
    if fac.get("property_id") != prop.get("id") or fac.get("type") != "warehouse":
        fail("warehouse Facility must belong to Lote 1 Property")
    if asset.get("facility_id") != fac.get("id"):
        fail("well Asset must belong to warehouse Facility")
    if placement.get("entity_type") != "asset" or placement.get("entity_id") != asset.get("id"):
        fail("ANA coordinate must belong to the well Asset")
    if placement.get("entity_id") == "site:20501523837:reference-1":
        fail("ANA Asset Placement cannot target canonical Site")

    if rel.get("property_id") != prop.get("id"):
        fail("relationship Property mismatch")
    if rel.get("site_id") != "site:20501523837:reference-1":
        fail("relationship must target canonical Site")
    if rel.get("relation") != "distinct_property":
        fail("CONTRACT 026 relation regression")
    if rel.get("operationally_related") is not True:
        fail("operational relationship regression")

    check_urls(properties + facilities + placements + relationships)

    audit26 = json.loads(AUDIT_026.read_text(encoding="utf-8"))
    if audit26.get("contract") != "026" or audit26.get("outreach_performed") is not False:
        fail("invalid CONTRACT 026 audit")
    resolution = audit26.get("resolution", {})
    if resolution.get("relation") != "distinct_property":
        fail("CONTRACT 026 audit relation regression")
    if resolution.get("adjacency_proven") is not False:
        fail("adjacency must remain unproven")
    if resolution.get("creates_site") is not False or resolution.get("changes_site_placement") is not False:
        fail("CONTRACT 026 must not mutate Site state")

    audit27 = json.loads(AUDIT_027.read_text(encoding="utf-8"))
    if audit27.get("contract") != "027" or audit27.get("outreach_performed") is not False:
        fail("invalid CONTRACT 027 audit")
    explomin = audit27.get("explomin", {})
    if explomin.get("placement_owner_type") != "asset":
        fail("typed Placement owner must be Asset")
    if explomin.get("site_placement_changed") is not False:
        fail("Site Placement must remain unchanged")
    if explomin.get("new_site_created") is not False:
        fail("CONTRACT 027 must not create a Site")

    print(
        "Property/facility semantics OK: 1 Property, 1 Facility, 1 Asset, "
        "1 typed Asset Placement; CONTRACT 026 DISTINCT_PROPERTY preserved; "
        "no Site mutation; no outreach."
    )

if __name__ == "__main__":
    main()
