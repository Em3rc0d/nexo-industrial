#!/usr/bin/env python3
import json
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
COMPANIES = ROOT / "assets/data/companies.production.json"
DISCOVERIES = ROOT / "assets/data/sites.discovered.overlay.json"
OVERLAY = ROOT / "assets/data/site.placement.verified.overlay.json"

ALLOWED_QUALITIES = {
    "exact_address",
    "address_reference",
    "property_reference",
    "interpolated_address",
    "street_reference",
    "district_reference",
}
ALLOWED_CONFIDENCE = {"high", "medium", "low", "very_low", "unknown"}
ALLOWED_METHODS = {
    "official_coordinates",
    "field_observation",
    "public_geocoder",
    "manual_review",
}
ALLOWED_SOURCE_TYPES = {"url", "dataset", "user_activity"}

def fail(message):
    raise SystemExit(f"ERROR: {message}")

def main():
    companies = json.loads(COMPANIES.read_text(encoding="utf-8"))
    known_rucs = {str(row["ruc"]) for row in companies}
    known_sites = {f"site:{ruc}:reference-1" for ruc in known_rucs}

    discoveries = json.loads(DISCOVERIES.read_text(encoding="utf-8"))
    for row in discoveries.get("records", []):
        known_sites.add(str(row["site_id"]))

    document = json.loads(OVERLAY.read_text(encoding="utf-8"))
    if document.get("format") != "nexo-industrial-placement-verifications":
        fail("invalid placement verification format")
    if document.get("version") != 1:
        fail("unsupported placement verification version")

    records = document.get("records", [])
    if not isinstance(records, list):
        fail("records must be a list")

    ids = set()
    site_ids = set()
    evidence_ids = {}

    for row in records:
        record_id = str(row.get("id", "")).strip()
        site_id = str(row.get("site_id", "")).strip()
        if not record_id or record_id in ids:
            fail(f"invalid/duplicate placement verification id: {record_id}")
        ids.add(record_id)

        if site_id not in known_sites:
            fail(f"{record_id}: unknown Site {site_id}")
        if site_id in site_ids:
            fail(f"{record_id}: duplicate current placement verification for {site_id}")
        site_ids.add(site_id)

        try:
            lat = float(row["latitude"])
            lon = float(row["longitude"])
        except (KeyError, TypeError, ValueError):
            fail(f"{record_id}: invalid latitude/longitude")
        if not (-90 <= lat <= 90 and -180 <= lon <= 180):
            fail(f"{record_id}: coordinate out of range")

        quality = row.get("quality")
        if quality not in ALLOWED_QUALITIES:
            fail(f"{record_id}: invalid quality {quality}")
        if row.get("confidence") not in ALLOWED_CONFIDENCE:
            fail(f"{record_id}: invalid confidence")
        if row.get("method") not in ALLOWED_METHODS:
            fail(f"{record_id}: invalid method")

        nearby = row.get("nearby_ranking_eligible", False)
        navigation = row.get("navigation_eligible", False)
        if navigation and not nearby:
            fail(f"{record_id}: navigation cannot bypass nearby eligibility")
        if quality == "property_reference" and (nearby or navigation):
            fail(f"{record_id}: property_reference cannot enable proximity/navigation")

        evidence = row.get("evidence", [])
        if not isinstance(evidence, list) or not evidence:
            fail(f"{record_id}: evidence required")
        for item in evidence:
            evidence_id = str(item.get("id", "")).strip()
            locator = str(item.get("locator", "")).strip()
            source_type = item.get("source_type")
            if not evidence_id or not locator:
                fail(f"{record_id}: incomplete evidence")
            if source_type not in ALLOWED_SOURCE_TYPES:
                fail(f"{record_id}: invalid evidence source_type")
            if source_type == "url":
                parsed = urlparse(locator)
                if parsed.scheme != "https" or not parsed.netloc:
                    fail(f"{record_id}: URL evidence must use HTTPS")
            fingerprint = (source_type, locator)
            if evidence_id in evidence_ids and evidence_ids[evidence_id] != fingerprint:
                fail(f"{record_id}: conflicting evidence id {evidence_id}")
            evidence_ids[evidence_id] = fingerprint

    print(
        f"Placement verification overlay OK: {len(records)} records; "
        f"{len(site_ids)} Sites; {len(evidence_ids)} evidence refs."
    )

if __name__ == "__main__":
    main()
