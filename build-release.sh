#!/bin/bash
set -euo pipefail

APP_PATH="run/release/AlwaysHaveAPlan.app"
APP_VERSION="${APP_VERSION:-$(git describe --tags --exact-match 2>/dev/null | sed 's/^v//' || echo '0.0.0')}"
SIGNING_IDENTITY="${CODESIGN_IDENTITY:--}"
TIME_RANGE_TEST="${TMPDIR:-/tmp}/alwayshaveaplan-time-range-test-$$"
trap 'rm -f "$TIME_RANGE_TEST"' EXIT

echo "🧪 Testing event time ranges..."
swiftc Sources/App/EventTimeRange.swift Tests/EventTimeRangeTest.swift -o "$TIME_RANGE_TEST"
"$TIME_RANGE_TEST"

echo "🔨 Building AlwaysHaveAPlan in Release mode..."
swift build -c release

echo "📦 Creating app bundle..."
rm -rf "$APP_PATH"
mkdir -p "$APP_PATH/Contents/MacOS"
mkdir -p "$APP_PATH/Contents/Resources"

echo "📋 Copying executable..."
cp .build/release/AlwaysHaveAPlan "$APP_PATH/Contents/MacOS/AlwaysHaveAPlan"
chmod +x "$APP_PATH/Contents/MacOS/AlwaysHaveAPlan"

echo "📄 Copying Info.plist..."
cp Sources/App/Resources/InfoTemplate.plist "$APP_PATH/Contents/Info.plist"
plutil -insert CFBundleShortVersionString -string "$APP_VERSION" "$APP_PATH/Contents/Info.plist"
plutil -insert CFBundleVersion -string "$APP_VERSION" "$APP_PATH/Contents/Info.plist"

echo "🎨 Copying icon..."
cp Sources/App/Resources/AppIcon.icns "$APP_PATH/Contents/Resources/AppIcon.icns"

echo "🔏 Signing complete app bundle..."
if [[ "$SIGNING_IDENTITY" == "-" ]]; then
  codesign --force --options runtime --sign - "$APP_PATH"
else
  codesign --force --options runtime --timestamp --sign "$SIGNING_IDENTITY" "$APP_PATH"
fi
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "✅ Build complete! App bundle created at: $APP_PATH"
echo "📊 App size: $(du -sh "$APP_PATH" | cut -f1)"
