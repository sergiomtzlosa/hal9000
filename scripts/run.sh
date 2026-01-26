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

echo "==> Building Debug"
xcodebuild \
    -project HAL9000.xcodeproj \
    -scheme HAL9000 \
    -configuration Debug \
    -derivedDataPath build \
    CODE_SIGNING_ALLOWED=NO \
    build

APP="build/Build/Products/Debug/HAL9000.app"
echo "==> Launching $APP"
open "$APP"
