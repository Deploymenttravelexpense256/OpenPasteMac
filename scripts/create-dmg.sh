#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$DIST_DIR/OpenPasteMac.app"
DMG_PATH="$DIST_DIR/OpenPasteMac.dmg"
STAGING="$DIST_DIR/.dmg_staging"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: $APP_PATH not found. Run ./scripts/build-app.sh first."
    exit 1
fi

echo "▸ Creating DMG..."

rm -rf "$STAGING" "$DMG_PATH"
mkdir -p "$STAGING"

cp -r "$APP_PATH" "$STAGING/"
ln -sf /Applications "$STAGING/Applications"

hdiutil create \
    -volname "OpenPasteMac" \
    -srcfolder "$STAGING" \
    -ov \
    -format UDZO \
    -fs HFS+ \
    "$DMG_PATH"

rm -rf "$STAGING"

echo ""
echo "✓ Created: $DMG_PATH"
echo "  Share this file — users drag OpenPasteMac.app to Applications to install."
