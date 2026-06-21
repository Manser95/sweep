<div align="center">
  <img src="assets/banner.svg" width="760" alt="Sweep — a safe, transparent cleaner for macOS" />

  <p><strong>English</strong> · <a href="README.ru.md">Русский</a></p>

  <p>
    <img src="https://img.shields.io/badge/macOS-14%2B-1575F9?logo=apple&logoColor=white" alt="macOS 14+" />
    <img src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white" alt="Swift 6" />
    <img src="https://img.shields.io/badge/UI-SwiftUI-0A84FF" alt="SwiftUI" />
    <img src="https://img.shields.io/badge/dependencies-none-30D158" alt="No dependencies" />
    <img src="https://img.shields.io/badge/License-MIT-green" alt="MIT License" />
  </p>
</div>

**Sweep** is a native macOS app, in the spirit of CCleaner, built around one
principle: **nothing is ever removed without your review — and only from an
explicitly audited list of safe locations.** It reclaims disk space from caches,
logs, the Trash, and developer junk, and shows you live RAM usage.

<div align="center">
  <img src="assets/preview-dashboard.svg" width="720" alt="Sweep dashboard" />
</div>

## Why Sweep

Cache and junk pile up fast on macOS. Most "cleaners" are opaque, bundled with
trackers, or aggressive enough to delete things you actually need. Sweep is the
opposite:

- 🛡️ **Allowlist-first safety.** Sweep only touches a small, hand-audited set of
  roots. Every path is validated again right before deletion. Symlinks that point
  outside the safe roots are refused.
- 🗑️ **Reversible by default.** Items go to the Trash unless you explicitly choose
  permanent deletion. A confirmation dialog appears before any cleanup, with an
  extra warning when something would be deleted permanently.
- 🔍 **Transparent.** You see every item, its size, and its full path before you
  decide. No hidden actions.
- 🧾 **Honest reporting.** Moving to the Trash is never reported as "freed" space —
  that only happens once the Trash is emptied, and Sweep says so.
- 🌐 **Bilingual.** Switch between English, Russian, or System language on the fly.
- 🪶 **Lightweight & private.** Native SwiftUI, zero third-party dependencies,
  no telemetry, no network access.

## Features

| Area | What it cleans |
|------|----------------|
| **Application Caches** | Per-app caches in `~/Library/Caches` (apps rebuild them automatically) |
| **Logs & Crash Reports** | `~/Library/Logs`, CrashReporter |
| **Trash** | Empty the Trash to reclaim space immediately |
| **Developer Junk** | Xcode DerivedData, iOS DeviceSupport, CoreSimulator, SwiftPM, npm, Gradle, Homebrew, CocoaPods, pip |
| **Memory (RAM)** | Live memory-pressure stats + an honest "purge inactive memory" action |

Plus: free-disk overview, per-item Trash/Delete choice, select/deselect all,
and "Reveal in Finder".

## Safety model

The single chokepoint is [`SafetyGuard`](Sources/Sweep/Engine/SafetyGuard.swift).
Every removal passes through `validate()`:

1. **Allowlist** — the path must live inside one of a few explicit roots
   (`~/Library/Caches`, `~/Library/Logs`, `~/Library/Developer`, `~/.Trash`,
   `~/.npm`, `~/.gradle/caches`, `~/.cache`, CrashReporter).
2. **Denylist** (defense in depth) — Documents, Desktop, Downloads, iCloud Drive,
   Keychains, Mail, Messages, and **Xcode Archives** are always refused.
3. **System paths** (`/System`, `/usr`, `/Library`, …) are always refused.
4. **Symlink-escape protection** — paths are resolved, and the real target must
   still be inside an allowed root.
5. A root directory can never be deleted as a whole — only its contents.
6. **Re-validation immediately before deletion** — the UI's selection state is
   never trusted on its own.

You can verify all of this safely, without deleting anything:

```bash
swift run Sweep --dryrun
```

This prints what *would* be cleaned and runs two self-checks: a safety check
(every dangerous path must report `BLOCKED`) and a localization check (every UI
string is translated in both languages).

## Install

### Option A — Download the DMG

Download the latest `Sweep-x.y.z.dmg` from the
[**Releases**](https://github.com/Manser95/sweep/releases) page, open it, and drag
**Sweep** into **Applications**.

> The app is distributed ad-hoc-signed (not yet notarized). On first launch,
> right-click the app → **Open** to bypass Gatekeeper, or run
> `xattr -dr com.apple.quarantine /Applications/Sweep.app`.

### Option B — Build from source

**Requirements:** macOS 14+, Xcode 16 / Swift 6 (`xcode-select --install` for the
command-line tools is enough to build).

```bash
git clone https://github.com/Manser95/sweep.git
cd sweep

# Run during development
swift run Sweep

# Or build a distributable .app into dist/
./scripts/bundle.sh release
open dist/Sweep.app

# Or package a ready-to-ship DMG
./scripts/make-dmg.sh 0.1.0
```

### Full Disk Access

For Sweep to clean everything, grant it Full Disk Access:
**System Settings → Privacy & Security → Full Disk Access → add Sweep.app**.
Without it, Sweep still works but some protected caches will be skipped.

## A note on "memory"

Sweep frees **disk** space for real. **RAM cannot be "cleaned" by deleting
files** — macOS manages it for you. The Memory tab shows honest, live statistics
and offers a `purge` of inactive/compressible pages; the effect is usually short
lived. No magic, no snake oil.

## Architecture

```
Sources/Sweep/
  App/          — entry point, GUI activation
  Models/       — data types (categories, rules, items, formatter)
  Engine/       — SafetyGuard, catalog, scanner, cleaner, RAM + disk info
  Localization/ — Localizer (@Observable) + ru/en string table
  ViewModels/   — SweepModel (@Observable, @MainActor)
  Views/        — Dashboard, Category, Memory, reusable components
  main.swift    — entry + --dryrun mode
assets/         — icon.svg, AppIcon.icns, banner.svg, preview
scripts/        — bundle.sh, make-icon.sh, make-dmg.sh, release.sh
```

Built with SwiftUI, Swift Observation, and strict Swift 6 concurrency. No
third-party dependencies.

## Contributing

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). The golden
rule: **never weaken `SafetyGuard`.** New cleanup targets go through
[`CleanupCatalog`](Sources/Sweep/Engine/CleanupCatalog.swift), and new UI strings
go through the localization table (both languages).

## Roadmap

- Code signing & notarization for distribution
- Duplicate / large / old file finders, leftovers of uninstalled apps
- Per-profile browser cache targets (Chrome / Safari / Firefox)
- Scheduled automatic cleanups
- "Empty Trash now" after moving items to the Trash

## License

[MIT](LICENSE) © Sweep contributors
