#!/usr/bin/env bash
# SmartStylist simulator smoke script.
# Run from the repo root on macOS with Xcode installed.
# Usage: bash .claude/skills/run-smartstylist/smoke.sh [screenshot_path]
set -euo pipefail

BUNDLE_ID="com.rubenaparicio.SmartStylist"
SCREENSHOT="${1:-/tmp/smartstylist_screenshot.png}"
SIM_NAME="iPhone 16"

# ── 1. APIKeys.swift ────────────────────────────────────────────────────────
if [ ! -f "SmartStylist/Config/APIKeys.swift" ]; then
  echo "[setup] Creating stub APIKeys.swift (empty keys — app will show AI errors, UI still works)"
  cp SmartStylist/Config/APIKeys.swift.template SmartStylist/Config/APIKeys.swift
fi

# ── 2. Generate Xcode project ───────────────────────────────────────────────
echo "[setup] xcodegen generate"
xcodegen generate

# ── 3. Build for simulator ───────────────────────────────────────────────────
echo "[build] xcodebuild build ..."
BUILD_DIR="$(mktemp -d)/DerivedData"
xcodebuild build \
  -project SmartStylist.xcodeproj \
  -scheme SmartStylist \
  -sdk iphonesimulator \
  -configuration Debug \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | grep -E "(error:|warning:|Build succeeded|Build FAILED)" || true

# Locate the .app bundle
APP_PATH=$(find "$BUILD_DIR" -name "SmartStylist.app" -path "*/Debug-iphonesimulator/*" | head -1)
if [ -z "$APP_PATH" ]; then
  echo "[error] Could not find SmartStylist.app in $BUILD_DIR"
  exit 1
fi
echo "[build] App bundle: $APP_PATH"

# ── 4. Boot simulator ───────────────────────────────────────────────────────
SIM_UDID=$(xcrun simctl list devices available -j \
  | python3 -c "
import sys, json
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d.get('name') == '$SIM_NAME' and d.get('isAvailable'):
            print(d['udid'])
            exit()
")

if [ -z "$SIM_UDID" ]; then
  echo "[error] Simulator '$SIM_NAME' not found. Available simulators:"
  xcrun simctl list devices available | grep "iPhone"
  exit 1
fi
echo "[sim] Using $SIM_NAME ($SIM_UDID)"

STATE=$(xcrun simctl list devices -j | python3 -c "
import sys, json
data = json.load(sys.stdin)
for runtime, devices in data['devices'].items():
    for d in devices:
        if d['udid'] == '$SIM_UDID':
            print(d['state'])
            exit()
")

if [ "$STATE" != "Booted" ]; then
  echo "[sim] Booting $SIM_NAME ..."
  xcrun simctl boot "$SIM_UDID"
  # Wait for it to boot
  timeout 60 bash -c "until xcrun simctl list devices | grep '$SIM_UDID' | grep -q 'Booted'; do sleep 2; done"
fi

# ── 5. Install + launch app ─────────────────────────────────────────────────
echo "[sim] Installing app ..."
xcrun simctl install "$SIM_UDID" "$APP_PATH"

echo "[sim] Launching app ..."
xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID"

# Brief pause for the app to render its first frame
sleep 3

# ── 6. Screenshot ───────────────────────────────────────────────────────────
echo "[sim] Taking screenshot -> $SCREENSHOT"
xcrun simctl io "$SIM_UDID" screenshot "$SCREENSHOT"
echo "[done] Screenshot saved: $SCREENSHOT"
