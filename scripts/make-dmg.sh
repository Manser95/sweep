#!/usr/bin/env bash
# Builds a distributable Sweep DMG with a drag-to-install layout
# (Sweep.app + an Applications symlink). Uses only the built-in `hdiutil`, so it
# works locally and in headless CI with no extra dependencies.
#
# Usage: ./scripts/make-dmg.sh [version]   (default: dev)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-dev}"
APP="$ROOT/dist/Sweep.app"
DMG="$ROOT/dist/Sweep-${VERSION}.dmg"
VOLNAME="Sweep"

# Build the .app first, unless the caller already prepared dist/Sweep.app
# (e.g. notarize.sh, which staples the app before packaging — rebuilding here
# would discard the stapled ticket).
if [ "${SWEEP_DMG_NO_BUILD:-}" = "1" ] && [ -d "$APP" ]; then
    echo "▸ Using existing $APP (skip build)"
else
    "$ROOT/scripts/bundle.sh" release
fi

# Stage the disk-image contents.
STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
cp -R "$APP" "$STAGING/Sweep.app"
ln -s /Applications "$STAGING/Applications"

# Create a compressed disk image.
rm -f "$DMG"
hdiutil create \
    -volname "$VOLNAME" \
    -srcfolder "$STAGING" \
    -fs HFS+ \
    -format UDZO \
    -ov \
    "$DMG" >/dev/null

echo ""
echo "✓ DMG: $DMG"
echo "  Size: $(du -h "$DMG" | cut -f1)"
