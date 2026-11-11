# Changelog

## 1.0.4+7 — 2026-11-11 (People overlay in source; no new APK)

- Found 33 distinct public professional references across 21 existing RUCs, focused on purchasing, procurement, logistics and supplier relations. Provenance and role recency retained.
- Added `data/people_enrichment/2026-11-11_mining_people.json` to Flutter bundled assets and a separate People panel inside the business details view, with safe LinkedIn/source links.
- Kept historical references explicitly historical and separated 2 corporate-group contacts from specific subsidiaries. One previous public supplier-facing professional email preserved with revalidation warning; no private phone numbers or guessed emails, no inflated direct-company-contact counts.
- Extended `test/public_professionals_test.dart` for join integrity, 33 profiles/21 RUC, safe URLs, group association, historical flags, purpose-limited professional email and unchanged company phone/email counts.
- Added read-only public CMH company contacts and its B2M/eBIZ supplier registration page as a staged discovery (no forms submitted and no production contact coverage assertion).
- No emails, calls, LinkedIn messages, connection requests, WhatsApp messages, vendor registrations or forms submitted.
- Additional passive research: 72 RUC reviewed across 8 public business-contact batches. Net new phone/email for 40 RUC and five web-only channels; CMH and AKD business contact details already existed in baseline. Separate last batches cover Tecnomin Data, Explo Drilling Perú, SEA, Los Quenuales/Alpayana, OREX, TPE Paita, Paltarumi, Construplan and Mincotrall, while AKD contributed provenance only.
- Projected after rebuilding all eight batches: 291 phones, 174 emails, 297 with either, 302 including web-only; baseline production asset remains 267/157/270/272. **Not APK metrics**.
- Rejected six outdated/hiring-only numbers/emails from latest contractor review and excluded previously departed commercial manager for TPE Paita. No prospect contacted.
- **Validation gate pending:** Flutter SDK unavailable in the active runtime; code changes have not passed Flutter analysis, Flutter tests or an Android device smoke test. APK remains unchanged.

## 1.0.4+7 — 2026-11-11 (source/data; APK pending)

- Review first 24 high-priority pending accounts in Callao/Lima Sur: publish phone/email for 13 and business contact pages for 2 more; keep 9 pending corroboration.
- Increase master coverage to 267 phones, 157 emails, 270 accounts with either and 272 including reviewed web-only pages.
- Preserve source, review date, channel purpose and identity linkage by RUC; queue remaining 1,637 accounts without phone/email.
- Add contact-page actions and channel-purpose labels to the account detail.
- Flutter analysis clean; all 14 Flutter tests pass. No APK generated for this source/data checkpoint.

## 1.0.3+6 — 2026-11-10

- Recover 1,907 historical ElRUC representative/role references from Git commit 180813c, joined strictly by RUC and labeled separately from reachable contacts.
- Recover three missing business phones/emails from the saved 84-prospect directory, with website crosschecks and provenance.
- Restore total contact coverage to 254 phones / 145 emails / 257 accounts with either channel; this does not mean all 1,907 accounts are reachable.
- Add separate mailto actions for published email addresses.
- Add regression checks for historical-reference semantics, email URI extraction and production contact totals (12 Flutter tests pass).

## 1.0.2+5 — 2026-11-10

- Show every account in the current map viewport, removing the 90-account cap and fixed anchor radius.
- Search districts/provinces globally, with accent-insensitive matching, and frame map results.
- Separate header from map, cluster all company markers and show area/total counts.
- Verify Callao and southern coverage against the production dataset (9 Flutter tests pass).
- Rebuild release locally and verify identical production assets; geographic quality remains 370 direct / 1,537 address searches.

## 1.0.1+4 — 2026-11-10

- Restored the required commercial overlay for all 1,907 accounts from the hash-verified snapshot master.
- Fixed snapshot member-hash verification and enforced asset/commercial coverage before builds.
- Updated test fixtures for the current Company contract.
- Flutter analysis passes; all seven Flutter tests and eleven geocoding tests pass.
- Local Android build scripts suppress telemetry and report the current pubspec version.
- Geographic navigation remains 370 direct coordinates and 1,537 address searches; no historical coordinate total is inferred.

## 1.0.0+3 — 2026-11-09

### Added
- Audited geolocation overlay for 1,907 accounts.
- Five explicit location-quality tiers.
- Google Maps search fallback for approximate locations.
- Structured commercial activity entry with outcome, note, status, next step and follow-up date.
- Account filters by sector, location quality, management state and high priority.
- Offline dataset validator.
- Local Android bootstrap and release scripts.
- Canonical Nexo Industrial branding mark.

### Changed
- Proximity ranking now weights geographic evidence.
- Interpolated locations use approximate distance with penalty.
- Street/district references no longer compete as exact proximity.
- Activity tab now represents commercial history rather than notifications.
- App version set to 1.0.0+3.

### Data
- 1,907/1,907 accounts with coordinates.
- 334 exact address.
- 36 address reference.
- 137 interpolated address.
- 551 street reference.
- 849 district reference.
- 370 navigation eligible.

### Release gate
The source is prepared for MVP 1.0. The Android release APK still requires:
- `flutter analyze`;
- `flutter test`;
- `flutter build apk --release`;
- smoke test on a physical Android device.

Builds remain local; GitHub Actions is not used for APK compilation.
