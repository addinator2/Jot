#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

echo "Generating app icon..."
swift scripts/generate-icon.swift

echo "Building release binary..."
swift build -c release

APP_DIR=".build/bundle/jot.app/Contents/MacOS"
RES_DIR=".build/bundle/jot.app/Contents/Resources"
mkdir -p "$APP_DIR" "$RES_DIR"
cp .build/release/jot "$APP_DIR/jot"
cp .build/AppIcon.icns "$RES_DIR/AppIcon.icns"

# Info.plist
cat > ".build/bundle/jot.app/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>jot</string>
    <key>CFBundleIdentifier</key>
    <string>com.jot.app</string>
    <key>CFBundleName</key>
    <string>jot</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
</dict>
</plist>
EOF

# Embed build commit hash
BUILD_COMMIT=$(git rev-parse HEAD)
/usr/libexec/PlistBuddy -c "Add :JotBuildCommit string $BUILD_COMMIT" ".build/bundle/jot.app/Contents/Info.plist"

# Ad-hoc code sign
codesign --force --sign - ".build/bundle/jot.app"

echo "Done! App bundle at .build/bundle/jot.app"
echo "Run with: open .build/bundle/jot.app"
