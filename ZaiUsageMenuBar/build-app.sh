#!/bin/bash
set -e

APP_NAME="ZaiUsageMenuBar"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

# Build release binary
swift build -c release

# Create app bundle structure
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$MACOS/"

# Create Info.plist
cat > "$CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>ZaiUsageMenuBar</string>
    <key>CFBundleDisplayName</key>
    <string>Zai Usage</string>
    <key>CFBundleIdentifier</key>
    <string>com.zai.usage-menubar</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleExecutable</key>
    <string>ZaiUsageMenuBar</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSMainNibFile</key>
    <string></string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
PLIST

echo "App bundle created at: $APP_BUNDLE"
echo "Run with: open $APP_BUNDLE"

# Ad-hoc sign the app bundle for Gatekeeper compatibility
codesign --force --sign - --options runtime "$APP_BUNDLE"
echo "App bundle signed"
