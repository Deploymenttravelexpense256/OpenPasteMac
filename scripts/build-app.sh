#!/usr/bin/env bash
set -euo pipefail

# ─── Config ──────────────────────────────────────────────────────────────────
APP_NAME="ClipboardHistory"
BUNDLE_ID="com.jarprojects.clipboardhistory"
VERSION="1.0.0"
MIN_MACOS="13.0"

# ─── Paths ───────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DIST_DIR="$ROOT_DIR/dist"
APP_PATH="$DIST_DIR/$APP_NAME.app"
CONTENTS="$APP_PATH/Contents"

cd "$ROOT_DIR"

echo "▸ Building release binary..."
swift build -c release

echo "▸ Assembling .app bundle..."
rm -rf "$APP_PATH"
mkdir -p "$CONTENTS/MacOS" "$CONTENTS/Resources"

# Copy binary
cp ".build/release/$APP_NAME" "$CONTENTS/MacOS/"

# ─── Info.plist ──────────────────────────────────────────────────────────────
cat > "$CONTENTS/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>Clipboard History</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleVersion</key>
    <string>$VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$VERSION</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>$MIN_MACOS</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSAccessibilityUsageDescription</key>
    <string>Clipboard History needs accessibility access to automatically paste items into other apps when you select them.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Clipboard History uses Apple Events to manage clipboard content.</string>
</dict>
</plist>
PLIST

# ─── PkgInfo ─────────────────────────────────────────────────────────────────
printf "APPL????" > "$CONTENTS/PkgInfo"

echo ""
echo "✓ Built: $APP_PATH"
echo ""
echo "Next steps:"
echo "  Install to Applications:  cp -r \"$APP_PATH\" /Applications/"
echo "  Create DMG:               ./scripts/create-dmg.sh"
echo ""
echo "  To enable Launch at Login after installing:"
echo "  Right-click the menu bar icon → Launch at Login"
