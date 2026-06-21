# Contributing to Sweep

Thanks for your interest in improving Sweep! This is a safety-critical utility —
it deletes files — so contributions are held to a high bar around correctness and
transparency.

## Golden rules

1. **Never weaken `SafetyGuard`.** It is the single chokepoint for every removal.
   Changes that broaden what can be deleted need a clear rationale and tests.
2. **New cleanup targets go through [`CleanupCatalog`](Sources/Sweep/Engine/CleanupCatalog.swift)** —
   never hardcode a deletion path elsewhere. Prefer `RemovalMode.trash` and
   `selectedByDefault: false` for anything remotely sensitive.
3. **All user-facing strings are localized.** Add a `LocKey` case and both `ru`
   and `en` values in [`Localization.swift`](Sources/Sweep/Localization/Localization.swift).
   No hardcoded UI text.
4. **Default to reversible.** The Trash is the safe default; permanent delete is
   opt-in, per item.

## Getting started

```bash
git clone https://github.com/Manser95/sweep.git
cd sweep
swift build
swift run Sweep            # launch the GUI
swift run Sweep --dryrun   # read-only scan + self-checks
```

**Requirements:** macOS 14+, Swift 6 / Xcode 16.

## Before opening a PR

Run the checks — both must pass:

```bash
swift build
swift run Sweep --dryrun
```

`--dryrun` verifies that:

- every dangerous path reports `BLOCKED` (safety self-check), and
- every `LocKey` has a non-empty `ru` and `en` translation (localization check).

If you change the UI, please attach before/after screenshots.

## Code style

- Swift 6 language mode, strict concurrency. Keep filesystem work off the main
  actor; UI state lives on `@MainActor`.
- Match the surrounding style: clear names, concise comments that explain *why*.
- Keep the project dependency-free.

## Regenerating the app icon

The icon is generated from [`assets/icon.svg`](assets/icon.svg). If you change it:

```bash
./scripts/make-icon.sh     # requires rsvg-convert or cairosvg
```

Commit the regenerated `assets/AppIcon.icns` so building stays dependency-free.

## Reporting bugs

Open an issue with your macOS version, steps to reproduce, and — for anything
involving deletion — the output of `swift run Sweep --dryrun` (it lists no
personal file contents, only category names, sizes, and the safety check).
