#!/bin/bash
set -e

APP_NAME="ZaiUsageMenuBar"
BUILD_DIR=".build/release"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
CONTENTS="$APP_BUNDLE/Contents"
MACOS="$CONTENTS/MacOS"
RESOURCES="$CONTENTS/Resources"

resolve_signing_identity() {
    if [[ -n "${SIGNING_IDENTITY:-}" ]]; then
        echo "$SIGNING_IDENTITY"
        return
    fi

    # Prefer a real code-signing certificate so Keychain trust can persist across rebuilds.
    security find-identity -v -p codesigning | awk -F'"' '/"[^"]+"/ { print $2; exit }'
}

# Build release binary
swift build -c release

# Create app bundle structure
mkdir -p "$MACOS"
mkdir -p "$RESOURCES"

# Copy binary
cp "$BUILD_DIR/$APP_NAME" "$MACOS/"

# Generate .icns from asset catalog
ICONSET="$BUILD_DIR/AppIcon.iconset"
mkdir -p "$ICONSET"
ASSETS="$BUILD_DIR/${APP_NAME}_${APP_NAME}.bundle/Assets.xcassets/AppIcon.appiconset"
cp "$ASSETS/icon_16x16.png" "$ICONSET/icon_16x16.png"
cp "$ASSETS/icon_16x16@2x.png" "$ICONSET/icon_16x16@2x.png"
cp "$ASSETS/icon_32x32.png" "$ICONSET/icon_32x32.png"
cp "$ASSETS/icon_32x32@2x.png" "$ICONSET/icon_32x32@2x.png"
cp "$ASSETS/icon_128x128.png" "$ICONSET/icon_128x128.png"
cp "$ASSETS/icon_128x128@2x.png" "$ICONSET/icon_128x128@2x.png"
cp "$ASSETS/icon_256x256.png" "$ICONSET/icon_256x256.png"
cp "$ASSETS/icon_512x512.png" "$ICONSET/icon_256x256@2x.png"
cp "$ASSETS/icon_512x512.png" "$ICONSET/icon_512x512.png"
cp "$ASSETS/icon_512x512@2x.png" "$ICONSET/icon_512x512@2x.png"
iconutil -c icns "$ICONSET" -o "$RESOURCES/AppIcon.icns"

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
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
PLIST

echo "App bundle created at: $APP_BUNDLE"
echo "Run with: open $APP_BUNDLE"

SIGNING_IDENTITY="$(resolve_signing_identity)"

if [[ -z "$SIGNING_IDENTITY" ]]; then
    if [[ "${ALLOW_ADHOC_SIGNING:-0}" == "1" ]]; then
        SIGNING_IDENTITY="-"
        echo "Warning: no signing certificate found, using ad-hoc signing."
    else
        echo "Error: no code-signing identity found."
        echo "Set SIGNING_IDENTITY to a valid identity name, or set ALLOW_ADHOC_SIGNING=1 to force ad-hoc signing."
        echo "Tip: run 'security find-identity -v -p codesigning' to list identities."
        exit 1
    fi
fi

# Resolve the keychain containing the signing identity to avoid repeated unlock prompts
SIGNING_KEYCHAIN=""
if [[ "$SIGNING_IDENTITY" != "-" ]]; then
    # Find which keychain holds this identity
    SIGNING_KEYCHAIN=$(security find-identity -v -p codesigning | grep -F "\"$SIGNING_IDENTITY\"" | head -1 | grep -oE '/[^ "]+\.keychain-db' | head -1)
fi

CODESIGN_ARGS=(--force --deep --sign "$SIGNING_IDENTITY" --options runtime --timestamp=none)
if [[ -n "$SIGNING_KEYCHAIN" ]]; then
    CODESIGN_ARGS+=(--keychain "$SIGNING_KEYCHAIN")
fi

codesign "${CODESIGN_ARGS[@]}" "$APP_BUNDLE"
echo "App bundle signed with identity: $SIGNING_IDENTITY"
