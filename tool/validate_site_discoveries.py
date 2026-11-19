#!/usr/bin/env python3
import json
import re
from datetime import datetime
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
COMPANIES = ROOT / "assets/data/companies.production.json"
DISCOVERIES = ROOT / "assets/data/sites.discovered.overlay.json"

ALLOWED_FUNCTIONS = {
    "unknown", "headquarters", "office", "plant", "mine", "warehouse",
    "workshop", "shipyard", "terminal", "project_site",
}
ALLOWED_METHODS = {
    "official_source", "public_source", "field_observation", "manual_review",
}
ALLOWED_SOURCE_TYPES = {"url", "dataset", "user_activity"}

def fail(message):
    raise SystemExit(f"ERROR: {message}")

def normalize(value):
    return re.sub(r"[^a-z0-9]+", "", str(value).lower())

def parse_date(value, field, record_id):
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except ValueError:
        fail(f"{record_id}: invalid {field}: {value}")

def main():
    companies = json.loads(COMPANIES.read_text(encoding="utf-8"))
    companies_by_ruc = {str(row["ruc"]): row for row in companies}

    document = json.loads(DISCOVERIES.read_text(encoding="utf-8"))
    if document.get("format") != "nexo-industrial-site-discoveries":
        fail("invalid discovery format")
    if document.get("version") != 1:
        fail("unsupported discovery version")

    records = document.get("records", [])
    if not isinstance(records, list):
        fail("records must be a list")

    discovery_ids = set()
    site_ids = {f"site:{ruc}:reference-1" for ruc in companies_by_ruc}
    evidence_ids = {}

    for row in records:
        record_id = str(row.get("id", "")).strip()
        ruc = str(row.get("organization_ruc", "")).strip()
        site_id = str(row.get("site_id", "")).strip()
        label = str(row.get("display_label", "")).strip()

        if not record_id or record_id in discovery_ids:
            fail(f"invalid/duplicate discovery id: {record_id}")
        discovery_ids.add(record_id)

        if ruc not in companies_by_ruc:
            fail(f"{record_id}: unknown RUC {ruc}")
        if not site_id.startswith(f"site:{ruc}:"):
            fail(f"{record_id}: site_id/RUC mismatch")
        if site_id in site_ids:
            fail(f"{record_id}: duplicate/colliding site_id {site_id}")
        site_ids.add(site_id)

        if not label:
            fail(f"{record_id}: display_label required")
        company = companies_by_ruc[ruc]
        baseline_labels = [
            company.get("address_hq_verified"),
            company.get("fiscal_address"),
        ]
        for existing in baseline_labels:
            if existing and normalize(existing) == normalize(label):
                fail(f"{record_id}: discovery duplicates baseline address")

        if row.get("site_function") not in ALLOWED_FUNCTIONS:
            fail(f"{record_id}: invalid site_function")
        if row.get("method") not in ALLOWED_METHODS:
            fail(f"{record_id}: invalid method")
        if not row.get("discovered_at"):
            fail(f"{record_id}: discovered_at required")
        parse_date(row["discovered_at"], "discovered_at", record_id)

        # CONTRACT 023 creates identity first. Coordinate placement is a
        # separate truth and must not be invented from a postal address.
        if row.get("placement") not in (None, {}):
            fail(f"{record_id}: placement is out of scope for CONTRACT 023")

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
                fail(f"{record_id}: invalid source_type")
            if source_type == "url":
                parsed = urlparse(locator)
                if parsed.scheme != "https" or not parsed.netloc:
                    fail(f"{record_id}: URL evidence must use HTTPS")
            fingerprint = (source_type, locator)
            if evidence_id in evidence_ids and evidence_ids[evidence_id] != fingerprint:
                fail(f"{record_id}: conflicting evidence id {evidence_id}")
            evidence_ids[evidence_id] = fingerprint

    print(
        f"Site discovery overlay OK: {len(records)} discoveries; "
        f"{len(site_ids)} total site identities; {len(evidence_ids)} evidence refs."
    )

if __name__ == "__main__":
    main()
