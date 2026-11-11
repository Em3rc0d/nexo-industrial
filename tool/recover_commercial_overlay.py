#!/usr/bin/env python3
"""Rebuild the required commercial asset from the hash-verified saved master.
No new contacts, geographic promotions or commercial claims are inferred.
"""
import gzip
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "data/snapshots/2026-11-10/restored/nexo_snapshot_2026-11-10/Master_MK2_enriquecido_2026-11-10.json"
SOURCE_HASH = "859cbf6e373fb0446a927fa3daf9c0d21fd8acbc185e9d115c457c8a87e98946"
FIELDS = {
    'ruc': 'RUC',
    'pool': 'Pool',
    'priority': 'Prioridad Aurora/Sigma',
    'tier': 'Tier',
    'score': 'Score',
    'secondary_sectors': 'Sectores secundarios',
    'address_hq_verified': 'Dirección HQ verificada',
    'workers_sunat': 'Trabajadores SUNAT',
    'visible_coactive_debt': 'Deuda coactiva visible',
    'buyer_type': 'Buyer Type',
    'buys_for_third_parties': 'Compra para terceros',
    'primary_application': 'Aplicación principal',
    'aurora_fit': 'Aurora Fit',
    'sigma_fit': 'Sigma Fit',
    'priority_brand': 'Marca prioritaria',
    'aurora_recommendation': 'Familia Aurora probable',
    'sigma_recommendation': 'Sistema Sigma probable (validar)',
    'commercial_fit_reason': 'Motivo de fit comercial',
    'purchase_frequency': 'Frecuencia probable',
    'price_sensitivity': 'Sensibilidad a precio',
    'specification_level': 'Nivel de especificación',
    'volume_reason': 'Por qué puede comprar volumen',
    'purchase_model': 'Modelo de compra probable',
    'target_role_1': 'Cargo objetivo 1',
    'target_role_2': 'Cargo objetivo 2',
    'enrichment_status': 'Estado de enriquecimiento',
    'opening_script': 'Guion de apertura',
    'company_source': 'Fuente empresa',
    'contact_source': 'Fuente contacto',
    'source_date': 'Fecha fuente',
    'prospecting_status': 'Estado de prospección',
    'origin': 'Origen',
    'confidence': 'Confianza',
    'observations': 'Observaciones',
}

def main():
    raw = SOURCE.read_bytes()
    if hashlib.sha256(raw).hexdigest() != SOURCE_HASH:
        raise ValueError("Saved commercial master hash mismatch")
    rows = json.loads(raw)["records"]
    result = []
    for row in rows:
        item = {key: row.get(column) for key, column in FIELDS.items()}
        item["ruc"] = str(item["ruc"])
        item["contact"] = {
            "name": row.get("Persona pública verificada"),
            "phone": row.get("Teléfono público"),
            "email": row.get("Email público"),
            "source": row.get("Fuente contacto"),
        }
        result.append(item)
    expected = {str(x["ruc"]) for x in json.loads((ROOT / "assets/data/companies.production.json").read_text())}
    if len(result) != 1907 or len({x["ruc"] for x in result}) != 1907 or {x["ruc"] for x in result} != expected:
        raise ValueError("Commercial recovery must match all 1907 unique production RUCs")
    recovery = ROOT / "data/contact_recovery"
    manifest = json.loads((recovery / "manifest.json").read_text())
    registry_raw = (recovery / "registry_references_180813c.json.gz").read_bytes()
    if hashlib.sha256(registry_raw).hexdigest() != manifest["registry_archive_sha256"]:
        raise ValueError("Historical registry archive hash mismatch")
    registry_rows = json.loads(gzip.decompress(registry_raw))
    if len(registry_rows) != 1907 or len({x[0] for x in registry_rows}) != 1907 or {x[0] for x in registry_rows} != expected:
        raise ValueError("Historical registry RUC coverage mismatch")
    by_ruc = {x["ruc"]: x for x in result}
    for ruc, description in registry_rows:
        match = re.fullmatch(r"(.+) \(([^()]+)\)", description)
        if not match:
            raise ValueError("Unrecognized historical representative format: " + ruc)
        by_ruc[ruc]["contact"].update(
            registry_name=match[1], registry_role=match[2],
            registry_source=manifest["registry_source_label"],
            registry_verification_status=manifest["registry_verification_status"],
        )
    for row in manifest["channel_recoveries"]:
        item = by_ruc[row["ruc"]]
        contact = item["contact"]
        for field in ["phone", "email"]:
            if not contact.get(field) and row.get(field):
                contact[field] = row[field]
        contact["source"] = row["source_url"]
        item["contact_source"] = row["source_url"]
    for batch_path in sorted((ROOT / "data/contact_enrichment").glob("20*.json")):
        batch = json.loads(batch_path.read_text())
        seen = set()
        for row in batch["records"]:
            ruc = row["ruc"]
            if ruc not in by_ruc or ruc in seen:
                raise ValueError("Unknown or duplicate enrichment RUC: " + ruc)
            seen.add(ruc)
            if row.get("status") != "published_channel_not_contacted" or not row.get("source_url", "").startswith("https://"):
                raise ValueError("Enrichment record missing accepted status or source: " + ruc)
            item = by_ruc[ruc]
            contact = item["contact"]
            for field in ["phone", "email"]:
                if row.get(field) and not contact.get(field):
                    contact[field] = row[field]
            for field in ["website", "contact_page", "reviewed_on", "channel_purpose", "source_type", "notes", "additional_phones"]:
                if row.get(field):
                    contact[field] = row[field]
            sources = list(dict.fromkeys([row["source_url"]] + ([row["email_source_url"]] if row.get("email_source_url") else [])))
            sources = list(dict.fromkeys(([contact["source"]] if contact.get("source") else []) + sources))
            contact["source"] = " | ".join(sources)
            item["contact_source"] = contact["source"]
    payload = json.dumps(result, ensure_ascii=False, separators=(",", ":")).encode()
    target = ROOT / "assets/data/companies.commercial.overlay.json.gz"
    target.write_bytes(gzip.compress(payload, mtime=0))
    print(f"Recovered {len(result)} commercial records; SHA-256 {hashlib.sha256(target.read_bytes()).hexdigest()}")

if __name__ == "__main__":
    main()
