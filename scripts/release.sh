#!/usr/bin/env bash
# Local helper to cut a release: builds the DMG and (optionally) publishes it to
# GitHub via the gh CLI. In CI, releases are produced automatically by
# .github/workflows/release.yml when a v* tag is pushed.
#
# Usage:
#   ./scripts/release.sh 0.1.0            # build dist/Sweep-0.1.0.dmg
#   ./scripts/release.sh 0.1.0 --publish  # also create the GitHub release
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-dev}"
PUBLISH="${2:-}"
DMG="$ROOT/dist/Sweep-${VERSION}.dmg"

"$ROOT/scripts/make-dmg.sh" "$VERSION"

if [ "$PUBLISH" = "--publish" ]; then
    echo "▸ Publishing GitHub release v${VERSION}…"
    gh release create "v${VERSION}" "$DMG" \
        --title "Sweep v${VERSION}" \
        --generate-notes
else
    echo ""
    echo "To publish:"
    echo "  ./scripts/release.sh ${VERSION} --publish"
    echo "or push a tag to let CI build & publish it:"
    echo "  git tag v${VERSION} && git push origin v${VERSION}"
fi
