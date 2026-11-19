#!/usr/bin/env python3
import json
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
COMPANIES = ROOT / "assets/data/companies.production.json"
OVERLAY = ROOT / "assets/data/sites.verified.overlay.json"
DISCOVERIES = ROOT / "assets/data/sites.discovered.overlay.json"
RECONCILIATIONS = ROOT / "assets/data/site.identity.reconciliation.overlay.json"

ALLOWED_DECISIONS = {"operational", "not_operational"}
ALLOWED_FUNCTIONS = {
    "unknown", "headquarters", "office", "plant", "mine", "warehouse",
    "workshop", "shipyard", "terminal", "project_site",
}
ALLOWED_METHODS = {
    "public_source", "official_source", "field_observation", "manual_review",
}
ALLOWED_SOURCE_TYPES = {"url", "dataset", "user_activity"}

def fail(message):
    raise SystemExit(f"ERROR: {message}")

def parse_date(value, field, record_id):
    if value in (None, ""):
        return None
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        fail(f"{record_id}: invalid {field}: {value}")

def main():
    companies = json.loads(COMPANIES.read_text(encoding="utf-8"))
    known_rucs = {str(row["ruc"]) for row in companies}
    known_site_ids = {f"site:{ruc}:reference-1" for ruc in known_rucs}

    discoveries = json.loads(DISCOVERIES.read_text(encoding="utf-8"))
    for row in discoveries.get("records", []):
        known_site_ids.add(str(row.get("site_id", "")).strip())

    reconciliations = json.loads(RECONCILIATIONS.read_text(encoding="utf-8"))
    for row in reconciliations.get("records", []):
        if row.get("relation") == "same_site":
            left = str(row.get("left_site_id", "")).strip()
            right = str(row.get("right_site_id", "")).strip()
            canonical = str(row.get("canonical_site_id", "")).strip()
            alias = right if canonical == left else left
            known_site_ids.discard(alias)

    document = json.loads(OVERLAY.read_text(encoding="utf-8"))
    if document.get("format") != "nexo-industrial-site-verifications":
        fail("invalid format")
    if document.get("version") != 1:
        fail("unsupported version")

    records = document.get("records", [])
    if not isinstance(records, list):
        fail("records must be a list")

    ids = set()
    current_sites = set()
    evidence_ids = {}

    for row in records:
        record_id = str(row.get("id", "")).strip()
        if not record_id:
            fail("verification without id")
        if record_id in ids:
            fail(f"duplicate verification id: {record_id}")
        ids.add(record_id)

        ruc = str(row.get("organization_ruc", "")).strip()
        if ruc not in known_rucs:
            fail(f"{record_id}: unknown RUC {ruc}")

        site_id = str(row.get("site_id", "")).strip()
        if not site_id.startswith(f"site:{ruc}:"):
            fail(f"{record_id}: site_id/RUC mismatch: {site_id}")
        if site_id not in known_site_ids:
            fail(f"{record_id}: verification references unknown Site {site_id}")
        if site_id in current_sites:
            fail(f"{record_id}: duplicate current verification for {site_id}")
        current_sites.add(site_id)

        decision = row.get("decision")
        if decision not in ALLOWED_DECISIONS:
            fail(f"{record_id}: invalid decision {decision}")

        site_function = row.get("site_function")
        if site_function not in ALLOWED_FUNCTIONS:
            fail(f"{record_id}: invalid site_function {site_function}")
        if decision == "operational" and site_function == "unknown":
            fail(f"{record_id}: operational site requires concrete function")

        method = row.get("method")
        if method not in ALLOWED_METHODS:
            fail(f"{record_id}: invalid method {method}")

        verified_at = parse_date(row.get("verified_at"), "verified_at", record_id)
        if verified_at is None:
            fail(f"{record_id}: verified_at is required")

        valid_from = parse_date(row.get("valid_from"), "valid_from", record_id)
        valid_until = parse_date(row.get("valid_until"), "valid_until", record_id)
        start = valid_from or verified_at
        if valid_until is not None and valid_until < start:
            fail(f"{record_id}: valid_until precedes validity start")

        evidence = row.get("evidence", [])
        if not isinstance(evidence, list) or not evidence:
            fail(f"{record_id}: evidence is required")

        for item in evidence:
            evidence_id = str(item.get("id", "")).strip()
            locator = str(item.get("locator", "")).strip()
            source_type = item.get("source_type")
            if not evidence_id or not locator:
                fail(f"{record_id}: incomplete evidence")
            if source_type not in ALLOWED_SOURCE_TYPES:
                fail(f"{record_id}: invalid evidence source_type {source_type}")
            if source_type == "url":
                parsed = urlparse(locator)
                if parsed.scheme != "https" or not parsed.netloc:
                    fail(f"{record_id}: public URL evidence must use HTTPS")
            previous = evidence_ids.get(evidence_id)
            fingerprint = (source_type, locator)
            if previous is not None and previous != fingerprint:
                fail(f"{record_id}: conflicting evidence id {evidence_id}")
            evidence_ids[evidence_id] = fingerprint

    print(
        f"Site verification overlay OK: {len(records)} records; "
        f"{len(current_sites)} current sites; {len(evidence_ids)} evidence refs."
    )

if __name__ == "__main__":
    main()
