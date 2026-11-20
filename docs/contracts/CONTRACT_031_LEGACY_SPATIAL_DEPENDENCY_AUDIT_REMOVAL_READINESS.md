# CONTRACT 031 — Legacy Spatial Dependency Audit & Removal Readiness

## Decision

**GO FOR REMOVAL**

CONTRACT 031 audits the residual dependency on Company-level spatial fields after
CONTRACT 030 moved runtime behavior to RuntimeCompanySpatialView.

## Finding

One indirect production dependency remained:

AssetCompanyRepository filtered records through `company.hasMapCoordinates`.

That filter has been removed. Company loading is now independent from legacy
spatial validity.

## Readiness remediation

- Company spatial constructor arguments are optional compatibility fields.
- Company can be constructed without latitude/longitude/quality/eligibility.
- Google Maps tests consume RuntimeCompanySpatialView.
- production location-quality tests consume RuntimeCompanySpatialView.
- runtime tests no longer use Company geography as parity authority.
- map, ranking, navigation, detail and company loading contain zero direct or
  indirect Company spatial-authority accesses.

## Inventory

- production authority consumers: 0
- production indirect consumers: 0
- compatibility model files: 1 (Company domain only)
- serialization blockers: 0
- test fixture blockers: 0

## Removal authorization

CONTRACT 032 is authorized to physically remove:

- Company.latitude
- Company.longitude
- Company.locationQuality
- Company.locationConfidence
- Company.nearbyRankingEligible
- Company.navigationEligible
- legacy Company spatial getters
- legacy Company.fromJson geography parsing

The spatial datasets themselves are not removed. They remain inputs to Site /
EntityPlacement authority.
