# Changelog

All notable changes to this project are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.1] — 2026-06-21

### Added
- Signed & notarized release builds: `scripts/notarize.sh` (Developer ID +
  hardened runtime + `notarytool` + stapling for both the app and the DMG),
  optional signing in `release.yml`, and a setup guide in `SIGNING.md`.

## [0.1.0] — 2026-06-21

First public release.

### Added
- Native SwiftUI macOS app with sidebar navigation (Dashboard, cleanup
  categories, Memory).
- Cleanup categories: Application Caches, Logs & Crash Reports, Trash, and
  Developer Junk (Xcode DerivedData, iOS DeviceSupport, CoreSimulator, SwiftPM,
  npm, Gradle, Homebrew, CocoaPods, pip).
- `SafetyGuard` allowlist engine: explicit safe roots, denylist, system-path
  blocking, symlink-escape protection, and re-validation before every deletion.
- Scanner with real allocated-size calculation and per-item breakdown.
- Trash (default, reversible) or permanent delete per item.
- Pre-clean confirmation dialog with an extra warning for permanent deletion.
- Honest reporting that distinguishes "deleted" from "moved to Trash".
- Free-disk overview on the dashboard.
- Memory (RAM) tab with live pressure stats and a `purge` action.
- Bilingual UI (English / Russian / System) with on-the-fly switching.
- `--dryrun` mode: read-only scan plus safety and localization self-checks.
- App icon generated from `assets/icon.svg`; `bundle.sh` / `make-icon.sh` /
  `make-dmg.sh` / `release.sh` build scripts.
- Distributable DMG (drag-to-Applications layout) and a tag-triggered GitHub
  Actions workflow that builds and publishes the DMG to Releases automatically.

[Unreleased]: https://github.com/Manser95/sweep/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/Manser95/sweep/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/Manser95/sweep/releases/tag/v0.1.0
