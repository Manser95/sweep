#!/usr/bin/env bash
# Assembles a proper Sweep.app bundle from the SwiftPM build product.
# Usage: ./scripts/bundle.sh [release|debug]   (default: release)
set -euo pipefail

CONFIG="${1:-release}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Sweep"
BUILD_DIR="$ROOT/.build/$CONFIG"
APP="$ROOT/dist/$APP_NAME.app"

echo "▸ Building ($CONFIG)…"
( cd "$ROOT" && swift build -c "$CONFIG" )

echo "▸ Assembling $APP_NAME.app…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP/Contents/MacOS/$APP_NAME"

# App icon (generated from assets/icon.svg via scripts/make-icon.sh).
if [ -f "$ROOT/assets/AppIcon.icns" ]; then
    cp "$ROOT/assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
else
    echo "  (no assets/AppIcon.icns — run scripts/make-icon.sh to add an icon)"
fi

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>            <string>Sweep</string>
    <key>CFBundleDisplayName</key>     <string>Sweep</string>
    <key>CFBundleIdentifier</key>      <string>com.startups.sweep</string>
    <key>CFBundleVersion</key>         <string>1</string>
    <key>CFBundleShortVersionString</key> <string>0.1.0</string>
    <key>CFBundlePackageType</key>     <string>APPL</string>
    <key>CFBundleExecutable</key>      <string>Sweep</string>
    <key>CFBundleIconFile</key>        <string>AppIcon</string>
    <key>CFBundleIconName</key>        <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>  <string>14.0</string>
    <key>NSHighResolutionCapable</key> <true/>
    <key>LSApplicationCategoryType</key> <string>public.app-category.utilities</string>
</dict>
</plist>
PLIST

# Ad-hoc sign so it launches without "damaged" warnings on the build machine.
echo "▸ Ad-hoc signing…"
codesign --force --deep --sign - "$APP" >/dev/null 2>&1 || \
    echo "  (codesign skipped — install Xcode CLT to sign)"

echo "✓ Done: $APP"
echo ""
echo "Run with:  open \"$APP\""
echo "For full cleanup, grant Full Disk Access:"
echo "  System Settings → Privacy & Security → Full Disk Access → add Sweep.app"
