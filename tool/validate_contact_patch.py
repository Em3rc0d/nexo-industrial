#!/usr/bin/env python3
"""Offline, read-only audit of Nexo's approved public company contact patch.

No network access, calls, messages, form submissions or vendor registration.
Run from the repository root: python3 tool/validate_contact_patch.py
"""
from __future__ import annotations

import gzip
import json
import re
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "assets/data/companies.commercial.overlay.json.gz"
MASTER = ROOT / "assets/data/companies.production.json"
PATCH = ROOT / "assets/data/companies.contact.patch.json"
MANIFEST = ROOT / "assets/data/production/manifest.json"
PEOPLE = ROOT / "data/people_enrichment/2026-11-11_mining_people.json"
BATCH_DIR = ROOT / "data/contact_enrichment"


def contact_metrics(rows: list[dict]) -> dict[str, int]:
    phone = sum(bool((r["contact"].get("phone") or "").strip()) for r in rows)
    email = sum(bool((r["contact"].get("email") or "").strip()) for r in rows)
    either = sum(
        bool((r["contact"].get("phone") or "").strip())
        or bool((r["contact"].get("email") or "").strip())
        for r in rows
    )
    web = sum(
        bool((r["contact"].get("phone") or "").strip())
        or bool((r["contact"].get("email") or "").strip())
        or str(r["contact"].get("contact_page") or "").startswith("https://")
        for r in rows
    )
    return {
        "with_phone": phone,
        "with_email": email,
        "with_phone_or_email": either,
        "with_phone_email_or_reviewed_contact_page": web,
        "without_phone_or_email": len(rows) - either,
    }


def assert_https(url: str) -> None:
    parsed = urlparse(url)
    assert parsed.scheme == "https" and parsed.netloc, url


def main() -> None:
    master = json.loads(MASTER.read_text(encoding="utf-8"))
    original = json.loads(gzip.decompress(BASE.read_bytes()).decode("utf-8"))
    patch = json.loads(PATCH.read_text(encoding="utf-8"))
    people = json.loads(PEOPLE.read_text(encoding="utf-8"))
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))

    master_rucs = {str(row["ruc"]) for row in master}
    base_rucs = {str(row["ruc"]) for row in original}
    assert len(master) == len(original) == len(master_rucs) == len(base_rucs) == 1907
    assert master_rucs == base_rucs

    # No new accounts. An immutable base copy is intentionally preserved.
    merged = {str(row["ruc"]): dict(row, contact=dict(row["contact"])) for row in original}
    base_metrics = contact_metrics(original)
    assert len(patch["records"]) == 31, len(patch["records"])
    seen = set()

    for row in patch["records"]:
        ruc = str(row["ruc"])
        assert re.fullmatch("[0-9]{11}", ruc), ruc
        assert ruc in base_rucs and ruc not in seen, ruc
        seen.add(ruc)
        assert row["status"] == "published_channel_not_contacted"
        assert_https(row["source_url"])
        for key in ("source_batch",):
            assert (ROOT / row[key]).is_file(), row
        contact = merged[ruc]["contact"]
        for key in ("phone", "email"):
            if not (contact.get(key) or "").strip() and (row.get(key) or "").strip():
                contact[key] = row[key]
        for key in ("website", "contact_page", "reviewed_on", "channel_purpose",
                    "source_type", "notes"):
            if row.get(key):
                contact[key] = row[key]
        for key in ("source_url", "email_source_url"):
            if row.get(key):
                assert_https(row[key])

    # Check all accepted source batches and the independent review queue.
    batches = sorted(BATCH_DIR.glob("20*.json"))
    accepted = []
    reviews = []
    for file in batches:
        batch = json.loads(file.read_text(encoding="utf-8"))
        assert batch.get("outreach_performed", False) is False, file
        accepted.extend(batch.get("records", []))
        reviews.extend(batch.get("reviews", []))
    assert len(batches) == 8, len(batches)
    assert len(accepted) == 46, len(accepted)
    assert len({x["ruc"] for x in accepted}) == 46
    assert len(reviews) == 26
    assert len(accepted) + len(reviews) == 72
    assert len(people["records"]) == 33
    assert len({str(x["ruc"]) for x in people["records"]}) == 21
    assert {str(x["ruc"]) for x in people["records"]}.issubset(master_rucs)

    effective = contact_metrics(list(merged.values()))
    expected_base = {
        "with_phone": 267,
        "with_email": 157,
        "with_phone_or_email": 270,
        "with_phone_email_or_reviewed_contact_page": 272,
        "without_phone_or_email": 1637,
    }
    expected_effective = {
        "with_phone": 291,
        "with_email": 174,
        "with_phone_or_email": 297,
        "with_phone_email_or_reviewed_contact_page": 302,
        "without_phone_or_email": 1610,
    }
    assert base_metrics == expected_base, (base_metrics, expected_base)
    assert effective == expected_effective, (effective, expected_effective)

    for key, value in expected_base.items():
        assert manifest["base_commercial_contact_coverage"][key] == value
    for key, value in expected_effective.items():
        assert manifest["contact_coverage"][key] == value

    # Directly inspect critical edge cases: CMH and AKD remain unchanged.
    old = {r["ruc"]: r for r in original}
    for ruc in ("20136150473", "20470234599"):
        assert merged[ruc]["contact"]["phone"] == old[ruc]["contact"]["phone"]
        assert merged[ruc]["contact"]["email"] == old[ruc]["contact"]["email"]

    print("OK: 1,907 unique RUC; 31 patched; 46 accepted research RUC;")
    print("    33 public people across 21 RUC; no communications performed.")
    print("Base:", base_metrics)
    print("Effective-source projection:", effective)
    print("APK remains unverified until Flutter test/build/smoke-test.")


if __name__ == "__main__":
    main()
