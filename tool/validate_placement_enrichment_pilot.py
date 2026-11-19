#!/usr/bin/env python3
import json
import math
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
COMPANIES = ROOT / "assets/data/companies.production.json"
DISCOVERIES = ROOT / "assets/data/sites.discovered.overlay.json"
OVERLAY = ROOT / "assets/data/site.placement.verified.overlay.json"
PILOT = ROOT / "data/site_enrichment/2026-11-19_placement_enrichment_pilot.json"

def fail(message):
    raise SystemExit(f"ERROR: {message}")

def utm_to_latlon(easting, northing, zone, northern=False):
    a = 6378137.0
    e = 0.08181919084262149
    e1sq = e * e / (1 - e * e)
    k0 = 0.9996

    x = easting - 500000.0
    y = northing if northern else northing - 10000000.0

    m = y / k0
    mu = m / (
        a * (1 - e * e / 4 - 3 * e ** 4 / 64 - 5 * e ** 6 / 256)
    )
    e1 = (1 - math.sqrt(1 - e * e)) / (1 + math.sqrt(1 - e * e))

    j1 = 3 * e1 / 2 - 27 * e1 ** 3 / 32
    j2 = 21 * e1 ** 2 / 16 - 55 * e1 ** 4 / 32
    j3 = 151 * e1 ** 3 / 96
    j4 = 1097 * e1 ** 4 / 512

    fp = (
        mu
        + j1 * math.sin(2 * mu)
        + j2 * math.sin(4 * mu)
        + j3 * math.sin(6 * mu)
        + j4 * math.sin(8 * mu)
    )

    sin_fp = math.sin(fp)
    cos_fp = math.cos(fp)
    tan_fp = math.tan(fp)
    c1 = e1sq * cos_fp ** 2
    t1 = tan_fp ** 2
    n1 = a / math.sqrt(1 - e * e * sin_fp ** 2)
    r1 = a * (1 - e * e) / (1 - e * e * sin_fp ** 2) ** 1.5
    d = x / (n1 * k0)

    lat = fp - (n1 * tan_fp / r1) * (
        d ** 2 / 2
        - (5 + 3 * t1 + 10 * c1 - 4 * c1 ** 2 - 9 * e1sq) * d ** 4 / 24
        + (
            61
            + 90 * t1
            + 298 * c1
            + 45 * t1 ** 2
            - 252 * e1sq
            - 3 * c1 ** 2
        )
        * d ** 6
        / 720
    )

    lon0 = math.radians((zone - 1) * 6 - 180 + 3)
    lon = lon0 + (
        d
        - (1 + 2 * t1 + c1) * d ** 3 / 6
        + (
            5
            - 2 * c1
            + 28 * t1
            - 3 * c1 ** 2
            + 8 * e1sq
            + 24 * t1 ** 2
        )
        * d ** 5
        / 120
    ) / cos_fp

    return math.degrees(lat), math.degrees(lon)

def main():
    companies = json.loads(COMPANIES.read_text(encoding="utf-8"))
    known_rucs = {str(row["ruc"]) for row in companies}
    known_sites = {f"site:{ruc}:reference-1" for ruc in known_rucs}

    discoveries = json.loads(DISCOVERIES.read_text(encoding="utf-8"))
    for row in discoveries.get("records", []):
        known_sites.add(str(row["site_id"]))

    overlay = json.loads(OVERLAY.read_text(encoding="utf-8"))
    if overlay.get("records") != []:
        fail("CONTRACT 024 pilot expects zero accepted production placements")

    pilot = json.loads(PILOT.read_text(encoding="utf-8"))
    if pilot.get("format") != "nexo-industrial-placement-enrichment-pilot":
        fail("invalid pilot format")
    if pilot.get("version") != 1:
        fail("unsupported pilot version")
    if pilot.get("outreach_performed") is not False:
        fail("pilot must not perform outreach")

    reviews = pilot.get("reviews", [])
    if len(reviews) != 1:
        fail("CONTRACT 024 baseline expects one reviewed placement candidate")

    review = reviews[0]
    if str(review.get("organization_ruc")) not in known_rucs:
        fail("review references unknown RUC")
    if review.get("outcome") != "rejected_site_identity_ambiguous":
        fail("candidate must remain rejected while Site identity is ambiguous")
    if review.get("accepted_verification_id") is not None:
        fail("rejected candidate cannot have accepted verification id")

    candidate_sites = review.get("candidate_site_ids", [])
    if len(candidate_sites) != 2 or any(site not in known_sites for site in candidate_sites):
        fail("candidate Site identities mismatch")

    source = review.get("source_coordinate") or {}
    if source.get("crs") != "EPSG:32718":
        fail("source CRS must remain EPSG:32718")
    if source.get("easting_m") != 287610 or source.get("northing_m") != 8646165:
        fail("source UTM coordinate drift")

    lat, lon = utm_to_latlon(287610, 8646165, 18, northern=False)
    derived = review.get("derived_wgs84") or {}
    if abs(float(derived.get("latitude")) - lat) > 0.000001:
        fail("derived latitude does not match EPSG transformation")
    if abs(float(derived.get("longitude")) - lon) > 0.000001:
        fail("derived longitude does not match EPSG transformation")

    for url in review.get("evidence_urls", []):
        parsed = urlparse(url)
        if parsed.scheme != "https" or not parsed.netloc:
            fail(f"pilot evidence must use HTTPS: {url}")

    summary = pilot.get("summary") or {}
    expected = {
        "reviewed": 1,
        "accepted": 0,
        "rejected": 1,
        "production_placements_added": 0,
    }
    for key, value in expected.items():
        if summary.get(key) != value:
            fail(f"summary.{key} mismatch")

    print(
        "Placement enrichment pilot OK: 1 reviewed; 0 accepted; "
        "1 rejected for Site identity ambiguity; no outreach."
    )

if __name__ == "__main__":
    main()
