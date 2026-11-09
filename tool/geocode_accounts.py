#!/usr/bin/env python3
"""
Nexo Industrial - address-level geocoding pipeline.

Input:
  JSON array with at least:
    - ruc
    - name
    - geography.latitude / longitude (district fallback)
    - geography.precision = "district_reference"

Output:
  Same records enriched with SUNAT/OpenRUC fiscal address and, when a
  trustworthy geocoder result exists, address-level coordinates.

Important:
- The real commercial dataset must remain outside this public repository.
- Public Nominatim is ONLY an optional one-time enrichment path.
- It is single-threaded, cached and <= 1 request/sec by design.
- For recurring/production geocoding use a private/self-hosted provider.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from typing import Any

OPENRUC_URL = "https://openruc.com/api/ruc/{ruc}"
NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"

DEFAULT_USER_AGENT = (
    "NexoIndustrial/0.1 "
    "(one-time internal dataset geocoding; https://github.com/Em3rc0d/nexo-industrial)"
)

MIN_REQUEST_INTERVAL_SECONDS = 1.1


def normalize(value: str | None) -> str:
    value = (value or "").strip().upper()
    value = unicodedata.normalize("NFD", value)
    value = "".join(ch for ch in value if unicodedata.category(ch) != "Mn")
    value = re.sub(r"[^A-Z0-9 ]+", " ", value)
    return re.sub(r"\s+", " ", value).strip()


def load_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as fh:
        return json.load(fh)


def save_json(path: Path, payload: Any) -> None:
    tmp = path.with_suffix(path.suffix + ".tmp")
    with tmp.open("w", encoding="utf-8") as fh:
        json.dump(payload, fh, ensure_ascii=False, indent=2)
    tmp.replace(path)


def http_json(url: str, user_agent: str, timeout: int = 30) -> Any:
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": user_agent,
            "Accept": "application/json",
        },
    )
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))


class Cache:
    def __init__(self, path: Path) -> None:
        self.path = path
        self.data: dict[str, Any] = {}
        if path.exists():
            self.data = load_json(path)

    def get(self, namespace: str, key: str) -> Any | None:
        return self.data.get(namespace, {}).get(key)

    def put(self, namespace: str, key: str, value: Any) -> None:
        self.data.setdefault(namespace, {})[key] = value
        save_json(self.path, self.data)


class RateLimiter:
    def __init__(self, interval_seconds: float) -> None:
        self.interval_seconds = interval_seconds
        self.last_request_at = 0.0

    def wait(self) -> None:
        elapsed = time.monotonic() - self.last_request_at
        if elapsed < self.interval_seconds:
            time.sleep(self.interval_seconds - elapsed)
        self.last_request_at = time.monotonic()


def fetch_openruc(ruc: str, cache: Cache, user_agent: str) -> dict[str, Any] | None:
    cached = cache.get("openruc", ruc)
    if cached is not None:
        return cached

    try:
        result = http_json(OPENRUC_URL.format(ruc=ruc), user_agent)
    except urllib.error.HTTPError as exc:
        if exc.code == 404:
            cache.put("openruc", ruc, {"_not_found": True})
            return None
        raise

    cache.put("openruc", ruc, result)
    return result


def geocode_nominatim(
    query: str,
    cache: Cache,
    limiter: RateLimiter,
    user_agent: str,
) -> list[dict[str, Any]]:
    cached = cache.get("nominatim", query)
    if cached is not None:
        return cached

    limiter.wait()
    params = urllib.parse.urlencode(
        {
            "q": query,
            "format": "jsonv2",
            "addressdetails": 1,
            "countrycodes": "pe",
            "limit": 3,
        }
    )
    result = http_json(f"{NOMINATIM_URL}?{params}", user_agent)
    cache.put("nominatim", query, result)
    return result


def score_candidate(candidate: dict[str, Any], target: dict[str, str]) -> float:
    address = candidate.get("address") or {}
    text = normalize(candidate.get("display_name"))
    score = 0.0

    district = normalize(target.get("district"))
    province = normalize(target.get("province"))
    department = normalize(target.get("department"))

    if district and district in text:
        score += 0.50
    if province and province in text:
        score += 0.20
    if department and department in text:
        score += 0.15

    candidate_country = normalize(address.get("country_code"))
    if candidate_country == "PE":
        score += 0.10

    result_type = normalize(candidate.get("type"))
    if result_type in {
        "HOUSE",
        "BUILDING",
        "COMMERCIAL",
        "INDUSTRIAL",
        "OFFICE",
        "COMPANY",
    }:
        score += 0.05

    return min(score, 1.0)


def build_query(openruc: dict[str, Any], geo: dict[str, Any]) -> str:
    pieces = [
        openruc.get("direccion"),
        geo.get("district"),
        geo.get("province"),
        geo.get("department"),
        "Peru",
    ]
    return ", ".join(str(piece).strip() for piece in pieces if piece)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument(
        "--cache",
        type=Path,
        default=Path(".cache/nexo_geocode_cache.json"),
    )
    parser.add_argument(
        "--provider",
        choices=["none", "nominatim"],
        default="none",
        help=(
            "none = enrich SUNAT address/ubigeo only; "
            "nominatim = one-time address geocoding."
        ),
    )
    parser.add_argument(
        "--i-accept-osmf-policy",
        action="store_true",
        help=(
            "Required for public Nominatim. Confirms deliberate acceptance of "
            "https://operations.osmfoundation.org/policies/nominatim/"
        ),
    )
    parser.add_argument(
        "--min-match-score",
        type=float,
        default=0.70,
        help="Minimum administrative consistency score to promote a geocode.",
    )
    args = parser.parse_args()

    if args.provider == "nominatim" and not args.i_accept_osmf_policy:
        parser.error(
            "--provider nominatim requires --i-accept-osmf-policy. "
            "Read the OSMF policy first."
        )

    args.cache.parent.mkdir(parents=True, exist_ok=True)

    user_agent = os.environ.get("NEXO_GEOCODER_USER_AGENT", DEFAULT_USER_AGENT)
    cache = Cache(args.cache)
    limiter = RateLimiter(MIN_REQUEST_INTERVAL_SECONDS)

    records = load_json(args.input)
    if not isinstance(records, list):
        raise ValueError("Input must be a JSON array.")

    counters = {
        "total": len(records),
        "openruc_ok": 0,
        "address_geocoded": 0,
        "district_fallback": 0,
        "unresolved": 0,
    }

    for index, record in enumerate(records, start=1):
        ruc = str(record.get("ruc", "")).strip()
        geo = record.setdefault("geography", {})

        if len(ruc) != 11:
            geo["geocoding_note"] = "RUC inválido o ausente."
            counters["unresolved"] += 1
            continue

        openruc = fetch_openruc(ruc, cache, user_agent)
        if not openruc or openruc.get("_not_found"):
            geo["geocoding_note"] = "RUC no encontrado en OpenRUC; se conserva fallback."
            counters["district_fallback"] += 1
            continue

        counters["openruc_ok"] += 1
        record["sunat"] = {
            "estado": openruc.get("estado"),
            "condicion": openruc.get("condicion"),
            "direccion_fiscal": openruc.get("direccion"),
            "ubigeo": openruc.get("ubigeo"),
            "source": openruc.get("source"),
            "as_of": openruc.get("as_of"),
        }

        if args.provider == "none" or not openruc.get("direccion"):
            geo["geocoding_note"] = "Dirección SUNAT enriquecida; sin geocodificación de calle."
            counters["district_fallback"] += 1
            continue

        query = build_query(openruc, geo)
        candidates = geocode_nominatim(query, cache, limiter, user_agent)

        scored = [
            (score_candidate(candidate, geo), candidate)
            for candidate in candidates
        ]
        scored.sort(key=lambda item: item[0], reverse=True)

        if not scored or scored[0][0] < args.min_match_score:
            geo["geocoding_note"] = (
                "Sin match de dirección suficientemente consistente; "
                "se conserva referencia distrital."
            )
            counters["district_fallback"] += 1
            continue

        score, candidate = scored[0]
        lat = float(candidate["lat"])
        lon = float(candidate["lon"])

        geo.update(
            {
                "latitude": lat,
                "longitude": lon,
                "precision": "address_geocoded",
                "nearby_ranking_eligible": True,
                "navigation_eligible": True,
                "geocoder": "nominatim",
                "geocoder_match_score": round(score, 3),
                "geocoder_display_name": candidate.get("display_name"),
                "geocoding_note": (
                    "Geocodificación automática; validar visualmente cuentas "
                    "críticas antes de visita."
                ),
            }
        )
        counters["address_geocoded"] += 1

        if index % 25 == 0:
            save_json(args.output, records)
            print(
                f"[{index}/{len(records)}] "
                f"exact={counters['address_geocoded']} "
                f"fallback={counters['district_fallback']}"
            )

    save_json(args.output, records)

    summary_path = args.output.with_suffix(".summary.json")
    save_json(summary_path, counters)

    print(json.dumps(counters, ensure_ascii=False, indent=2))
    print(f"Output: {args.output}")
    print(f"Summary: {summary_path}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
