# Changelog

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
