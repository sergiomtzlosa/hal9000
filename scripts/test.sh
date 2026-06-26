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

echo "==> Building HALCore tests"
xcodebuild \
    -project HAL9000.xcodeproj \
    -scheme HAL9000 \
    -configuration Debug \
    -derivedDataPath build \
    CODE_SIGNING_ALLOWED=NO \
    build-for-testing

TEST_BUNDLE="build/Build/Products/Debug/HAL9000Tests.xctest"
if [[ ! -d "$TEST_BUNDLE" ]]; then
    echo "error: expected test bundle was not produced at $TEST_BUNDLE" >&2
    exit 1
fi

# Run the logic-test bundle directly. This exercises the same XCTest cases
# without requiring a GUI test host or testmanagerd, so it also works from
# headless sessions and remote shells.
echo "==> Running HALCore unit tests"
xcrun xctest "$TEST_BUNDLE"
