#!/usr/bin/env python3
import json
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
COMPANIES = ROOT / "assets/data/companies.production.json"
OVERLAY = ROOT / "assets/data/sites.verified.overlay.json"
PILOT = ROOT / "data/site_enrichment/2026-11-19_operational_site_pilot.json"

def fail(message):
    raise SystemExit(f"ERROR: {message}")

def https_url(value):
    parsed = urlparse(str(value))
    return parsed.scheme == "https" and bool(parsed.netloc)

def main():
    companies = json.loads(COMPANIES.read_text(encoding="utf-8"))
    companies_by_ruc = {str(row["ruc"]): row for row in companies}

    overlay = json.loads(OVERLAY.read_text(encoding="utf-8"))
    overlay_records = overlay.get("records", [])
    overlay_by_id = {row["id"]: row for row in overlay_records}

    pilot = json.loads(PILOT.read_text(encoding="utf-8"))
    if pilot.get("format") != "nexo-industrial-operational-site-enrichment-pilot":
        fail("invalid pilot format")
    if pilot.get("version") != 1:
        fail("unsupported pilot version")
    if pilot.get("outreach_performed") is not False:
        fail("pilot must not perform outreach")

    reviews = pilot.get("reviews")
    if not isinstance(reviews, list):
        fail("reviews must be a list")

    selection = pilot.get("selection") or {}
    if selection.get("sample_size") != len(reviews):
        fail("selection.sample_size does not match reviews")

    seen_rucs = set()
    accepted_ids = set()
    accepted = 0
    rejected = 0

    for row in reviews:
        ruc = str(row.get("ruc", "")).strip()
        if ruc not in companies_by_ruc:
            fail(f"unknown pilot RUC: {ruc}")
        if ruc in seen_rucs:
            fail(f"duplicate pilot RUC: {ruc}")
        seen_rucs.add(ruc)

        if row.get("company_name") != companies_by_ruc[ruc].get("name"):
            fail(f"{ruc}: company_name mismatch")

        expected_site = f"site:{ruc}:reference-1"
        if row.get("reference_site_id") != expected_site:
            fail(f"{ruc}: reference_site_id mismatch")

        for url in row.get("evidence_urls") or []:
            if not https_url(url):
                fail(f"{ruc}: evidence URL must be HTTPS: {url}")

        outcome = row.get("outcome")
        verification_id = row.get("verification_id")
        if outcome == "accepted":
            accepted += 1
            if not verification_id:
                fail(f"{ruc}: accepted review requires verification_id")
            if verification_id not in overlay_by_id:
                fail(f"{ruc}: verification missing from production overlay")
            if overlay_by_id[verification_id].get("organization_ruc") != ruc:
                fail(f"{ruc}: overlay verification RUC mismatch")
            accepted_ids.add(verification_id)
        else:
            rejected += 1
            if verification_id is not None:
                fail(f"{ruc}: rejected review cannot have verification_id")

    overlay_ids = set(overlay_by_id)
    if not accepted_ids.issubset(overlay_ids):
        fail("accepted pilot verification IDs must remain in production overlay")

    summary = pilot.get("summary") or {}
    if summary.get("reviewed") != len(reviews):
        fail("summary.reviewed mismatch")
    if summary.get("accepted") != accepted:
        fail("summary.accepted mismatch")
    if summary.get("rejected") != rejected:
        fail("summary.rejected mismatch")

    if len(reviews) != 6 or accepted != 4 or rejected != 2:
        fail(
            f"unexpected pilot baseline: reviewed={len(reviews)}, "
            f"accepted={accepted}, rejected={rejected}"
        )

    print(
        f"Operational site enrichment pilot OK: {len(reviews)} reviewed; "
        f"{accepted} accepted; {rejected} rejected; no outreach."
    )

if __name__ == "__main__":
    main()
