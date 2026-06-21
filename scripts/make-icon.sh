#!/usr/bin/env bash
# Regenerates the macOS app icon (assets/AppIcon.icns) from assets/icon.svg.
# Only maintainers need this — the generated .icns is committed, so building
# the app requires no SVG tooling.
#
# Requires one of: rsvg-convert (librsvg) or cairosvg.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SVG="$ROOT/assets/icon.svg"
ICONSET="$ROOT/assets/Sweep.iconset"
ICNS="$ROOT/assets/AppIcon.icns"

# Pick an available SVG rasterizer.
render() { # render <size> <out>
    local size="$1" out="$2"
    if command -v rsvg-convert >/dev/null 2>&1; then
        rsvg-convert -w "$size" -h "$size" "$SVG" -o "$out"
    elif command -v cairosvg >/dev/null 2>&1; then
        cairosvg "$SVG" -W "$size" -H "$size" -o "$out"
    else
        echo "error: need rsvg-convert or cairosvg (brew install librsvg)" >&2
        exit 1
    fi
}

rm -rf "$ICONSET"; mkdir -p "$ICONSET"

# size : filename
sizes=(
  "16:icon_16x16.png"
  "32:icon_16x16@2x.png"
  "32:icon_32x32.png"
  "64:icon_32x32@2x.png"
  "128:icon_128x128.png"
  "256:icon_128x128@2x.png"
  "256:icon_256x256.png"
  "512:icon_256x256@2x.png"
  "512:icon_512x512.png"
  "1024:icon_512x512@2x.png"
)

for entry in "${sizes[@]}"; do
    size="${entry%%:*}"; name="${entry##*:}"
    render "$size" "$ICONSET/$name"
done

iconutil -c icns "$ICONSET" -o "$ICNS"
rm -rf "$ICONSET"
echo "✓ Wrote $ICNS"
