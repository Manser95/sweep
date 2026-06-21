#!/usr/bin/env bash
# Builds a release Sweep.app and zips it for distribution (e.g. to attach to a
# GitHub Release). The zip is created with `ditto` so it preserves the bundle
# correctly for macOS.
#
# Usage: ./scripts/release.sh [version]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-dev}"
APP="$ROOT/dist/Sweep.app"
ZIP="$ROOT/dist/Sweep-${VERSION}-macos.zip"

"$ROOT/scripts/bundle.sh" release

rm -f "$ZIP"
( cd "$ROOT/dist" && ditto -c -k --sequesterRsrc --keepParent "Sweep.app" "$(basename "$ZIP")" )

echo ""
echo "✓ Release artifact: $ZIP"
echo "  Size: $(du -h "$ZIP" | cut -f1)"
echo ""
echo "Attach it to a GitHub Release:"
echo "  gh release create v${VERSION} \"$ZIP\" --title \"v${VERSION}\" --notes-file CHANGELOG.md"
