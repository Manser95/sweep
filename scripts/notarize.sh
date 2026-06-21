#!/usr/bin/env bash
# Builds, signs (Developer ID), notarizes and staples a distributable DMG.
#
# Prerequisites (see SIGNING.md):
#   • A "Developer ID Application" certificate in the keychain
#       (or set SWEEP_SIGN_IDENTITY to its name).
#   • Notarization credentials, either:
#       API key:  NOTARY_KEY=/path/AuthKey.p8  NOTARY_KEY_ID=...  NOTARY_ISSUER=...
#       or Apple ID:  NOTARY_APPLE_ID=...  NOTARY_PASSWORD=<app-specific>  NOTARY_TEAM_ID=...
#
# Usage: ./scripts/notarize.sh [version]   (default: dev)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-dev}"
APP="$ROOT/dist/Sweep.app"
DMG="$ROOT/dist/Sweep-${VERSION}.dmg"

# --- Resolve the signing identity ------------------------------------------
SIGN_ID="${SWEEP_SIGN_IDENTITY:-}"
if [ -z "$SIGN_ID" ]; then
    # `|| true`: grep exits non-zero when no Developer ID exists, which would
    # otherwise abort the script under `set -euo pipefail`.
    SIGN_ID="$(security find-identity -v -p codesigning 2>/dev/null \
        | grep 'Developer ID Application' | head -1 \
        | sed -E 's/^[^"]*"([^"]+)".*/\1/' || true)"
fi
if [ -z "$SIGN_ID" ]; then
    echo "error: no 'Developer ID Application' identity found. See SIGNING.md" >&2
    exit 1
fi
export SWEEP_SIGN_IDENTITY="$SIGN_ID"

# --- Build notarytool credential arguments ---------------------------------
if [ -n "${NOTARY_KEY:-}" ] && [ -n "${NOTARY_KEY_ID:-}" ] && [ -n "${NOTARY_ISSUER:-}" ]; then
    CRED=(--key "$NOTARY_KEY" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER")
elif [ -n "${NOTARY_APPLE_ID:-}" ] && [ -n "${NOTARY_PASSWORD:-}" ] && [ -n "${NOTARY_TEAM_ID:-}" ]; then
    CRED=(--apple-id "$NOTARY_APPLE_ID" --password "$NOTARY_PASSWORD" --team-id "$NOTARY_TEAM_ID")
else
    echo "error: notarization credentials not set. See SIGNING.md" >&2
    exit 1
fi

# --- 1. Build + sign the app (bundle.sh picks up SWEEP_SIGN_IDENTITY) -------
"$ROOT/scripts/bundle.sh" release

# --- 2. Notarize the app, then staple the ticket into it -------------------
APPZIP="$ROOT/dist/Sweep-app.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$APPZIP"
echo "▸ Submitting app for notarization (this can take a few minutes)…"
xcrun notarytool submit "$APPZIP" "${CRED[@]}" --wait
xcrun stapler staple "$APP"
rm -f "$APPZIP"

# --- 3. Package the stapled app into a DMG (no rebuild) --------------------
SWEEP_DMG_NO_BUILD=1 "$ROOT/scripts/make-dmg.sh" "$VERSION"

# --- 4. Sign, notarize and staple the DMG ----------------------------------
echo "▸ Signing DMG…"
codesign --force --timestamp --sign "$SIGN_ID" "$DMG"
echo "▸ Submitting DMG for notarization…"
xcrun notarytool submit "$DMG" "${CRED[@]}" --wait
xcrun stapler staple "$DMG"

echo ""
echo "✓ Notarized & stapled: $DMG"
xcrun stapler validate "$DMG" && echo "✓ Staple validated"
spctl --assess --type open --context context:primary-signature -vv "$DMG" 2>&1 | head -3 || true
