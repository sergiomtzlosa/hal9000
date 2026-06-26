#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v xcodegen >/dev/null 2>&1; then
    echo "error: xcodegen is required. Install it with: brew install xcodegen" >&2
    exit 1
fi

echo "==> Generating HAL9000.xcodeproj"
xcodegen generate

echo "==> Building Release"
# Clean through Xcode rather than deleting the whole derived-data directory.
# Finder can recreate .DS_Store files in build/ while rm is walking it, which
# makes a full rm -rf race-prone on some machines.
rm -rf dist/HAL9000.app 2>/dev/null || true
mkdir -p dist
xcodebuild \
    -project HAL9000.xcodeproj \
    -scheme HAL9000 \
    -configuration Release \
    -derivedDataPath build \
    CODE_SIGNING_ALLOWED=NO \
    clean build

APP="build/Build/Products/Release/HAL9000.app"
if [[ ! -d "$APP" ]]; then
    echo "error: expected app was not produced at $APP" >&2
    exit 1
fi

echo "==> Copying to dist/HAL9000.app"
ditto "$APP" "dist/HAL9000.app"

echo "==> Ad-hoc signing"
codesign --force --deep --sign - "dist/HAL9000.app"
codesign --verify --deep --strict --verbose=2 "dist/HAL9000.app"

echo "==> Verifying bundle"
plutil -lint "dist/HAL9000.app/Contents/Info.plist"
file "dist/HAL9000.app/Contents/Resources/HAL9000.icns"
/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "dist/HAL9000.app/Contents/Info.plist"

echo
echo "Release build ready: $ROOT/dist/HAL9000.app"
