#!/usr/bin/env python3
import json
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
COMPANIES = ROOT / "assets/data/companies.production.json"
DISCOVERIES = ROOT / "assets/data/sites.discovered.overlay.json"
PLACEMENTS = ROOT / "assets/data/companies.geolocation.overlay.json"
OVERLAY = ROOT / "assets/data/site.identity.reconciliation.overlay.json"
AUDIT = ROOT / "data/site_enrichment/2026-11-19_site_identity_reconciliation.json"

ALLOWED_RELATIONS = {"same_site", "adjacent_site", "distinct_site", "unknown"}
ALLOWED_METHODS = {
    "official_cross_reference",
    "official_source",
    "field_observation",
    "manual_review",
}
ALLOWED_CONFIDENCE = {"high", "medium", "low", "very_low", "unknown"}
ALLOWED_SOURCE_TYPES = {"url", "dataset", "user_activity"}

def fail(message):
    raise SystemExit(f"ERROR: {message}")

def main():
    companies = json.loads(COMPANIES.read_text(encoding="utf-8"))
    known_rucs = {str(row["ruc"]) for row in companies}
    sites = {
        f"site:{ruc}:reference-1": {
            "ruc": ruc,
            "has_baseline_placement": True,
        }
        for ruc in known_rucs
    }

    discoveries = json.loads(DISCOVERIES.read_text(encoding="utf-8"))
    for row in discoveries.get("records", []):
        site_id = str(row["site_id"])
        sites[site_id] = {
            "ruc": str(row["organization_ruc"]),
            "has_baseline_placement": False,
        }

    # Preserve the explicit assumption that all canonical RUC reference sites
    # still have one current placement in CONTRACT 024.
    geolocation = json.loads(PLACEMENTS.read_text(encoding="utf-8"))
    if len(geolocation) != len(known_rucs):
        fail("baseline geolocation count drift")

    document = json.loads(OVERLAY.read_text(encoding="utf-8"))
    if document.get("format") != "nexo-industrial-site-identity-reconciliations":
        fail("invalid reconciliation format")
    if document.get("version") != 1:
        fail("unsupported reconciliation version")

    records = document.get("records", [])
    if not isinstance(records, list):
        fail("records must be a list")

    ids = set()
    pairs = set()
    aliases = set()
    evidence_ids = {}

    for row in records:
        record_id = str(row.get("id", "")).strip()
        if not record_id or record_id in ids:
            fail(f"invalid/duplicate reconciliation id: {record_id}")
        ids.add(record_id)

        ruc = str(row.get("organization_ruc", "")).strip()
        left = str(row.get("left_site_id", "")).strip()
        right = str(row.get("right_site_id", "")).strip()
        relation = row.get("relation")
        canonical = row.get("canonical_site_id")

        if ruc not in known_rucs:
            fail(f"{record_id}: unknown RUC")
        if left == right:
            fail(f"{record_id}: reconciliation needs two distinct Site IDs")
        if left not in sites or right not in sites:
            fail(f"{record_id}: reconciliation references unknown Site")
        if sites[left]["ruc"] != ruc or sites[right]["ruc"] != ruc:
            fail(f"{record_id}: Site/RUC mismatch")

        pair = tuple(sorted((left, right)))
        if pair in pairs:
            fail(f"{record_id}: duplicate Site pair")
        pairs.add(pair)

        if relation not in ALLOWED_RELATIONS:
            fail(f"{record_id}: invalid relation {relation}")
        if row.get("method") not in ALLOWED_METHODS:
            fail(f"{record_id}: invalid method")
        if row.get("confidence") not in ALLOWED_CONFIDENCE:
            fail(f"{record_id}: invalid confidence")
        if not row.get("reviewed_at"):
            fail(f"{record_id}: reviewed_at required")

        if relation == "same_site":
            if canonical not in (left, right):
                fail(f"{record_id}: SAME_SITE requires canonical Site from pair")
            alias = right if canonical == left else left
            if sites[alias]["has_baseline_placement"]:
                fail(f"{record_id}: alias Site owns baseline Placement")
            if alias in aliases:
                fail(f"{record_id}: alias Site already reconciled")
            aliases.add(alias)
        elif canonical is not None:
            fail(f"{record_id}: only SAME_SITE may set canonical_site_id")

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

    audit = json.loads(AUDIT.read_text(encoding="utf-8"))
    if audit.get("format") != "nexo-industrial-site-identity-reconciliation-audit":
        fail("invalid reconciliation audit format")
    if audit.get("version") != 1:
        fail("unsupported reconciliation audit version")
    if audit.get("outreach_performed") is not False:
        fail("reconciliation audit must not perform outreach")

    assessments = audit.get("assessments", [])
    if len(assessments) != 2:
        fail("CONTRACT 025 baseline expects two assessments")
    outcomes = [row.get("outcome") for row in assessments]
    if outcomes.count("same_site") != 1 or outcomes.count("unknown") != 1:
        fail("CONTRACT 025 baseline expects one SAME_SITE and one UNKNOWN")

    summary = audit.get("summary", {})
    expected = {
        "assessments": 2,
        "same_site": 1,
        "adjacent_site": 0,
        "distinct_site": 0,
        "unknown": 1,
        "active_site_aliases_created": 1,
    }
    for key, value in expected.items():
        if summary.get(key) != value:
            fail(f"audit summary.{key} mismatch")

    for url in audit.get("evidence_urls", []):
        parsed = urlparse(url)
        if parsed.scheme != "https" or not parsed.netloc:
            fail(f"audit evidence URL must use HTTPS: {url}")

    print(
        f"Site identity reconciliation OK: {len(records)} records; "
        f"{len(aliases)} active aliases; {len(evidence_ids)} evidence refs; "
        "audit=1 SAME_SITE + 1 UNKNOWN; no outreach."
    )

if __name__ == "__main__":
    main()
