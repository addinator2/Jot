#!/bin/bash
set -euo pipefail

echo "Installing jot..."

# Check for required tools
if ! command -v swift &>/dev/null; then
    echo "Error: Swift is required. Install Xcode or Xcode Command Line Tools:"
    echo "  xcode-select --install"
    exit 1
fi

if ! command -v git &>/dev/null; then
    echo "Error: git is required."
    exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "Cloning repository..."
git clone --depth 1 https://github.com/furst/Jot.git "$WORK_DIR/Jot" 2>&1 | tail -1

cd "$WORK_DIR/Jot"

echo "Generating app icon..."
swift scripts/generate-icon.swift

echo "Building release binary..."
swift build -c release 2>&1 | tail -1

echo "Creating app bundle..."
APP_DIR="/Applications/jot.app/Contents/MacOS"
RES_DIR="/Applications/jot.app/Contents/Resources"
mkdir -p "$APP_DIR" "$RES_DIR"
cp .build/release/jot "$APP_DIR/jot"
cp .build/AppIcon.icns "$RES_DIR/AppIcon.icns"

cat > "/Applications/jot.app/Contents/Info.plist" << 'EOF'
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
/usr/libexec/PlistBuddy -c "Add :JotBuildCommit string $BUILD_COMMIT" "/Applications/jot.app/Contents/Info.plist"

codesign --force --sign - "/Applications/jot.app"

echo ""
echo "jot has been installed to /Applications/jot.app"
echo "Run it with: open /Applications/jot.app"
echo ""
echo "Tip: Use Cmd+Shift+N to capture notes from anywhere."
