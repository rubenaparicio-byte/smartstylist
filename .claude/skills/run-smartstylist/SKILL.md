---
name: run-smartstylist
description: Build, launch, and screenshot the SmartStylist iOS app on the simulator. Use when asked to run the app, see a change in the app, confirm a feature works, take a screenshot, or verify UI behaviour.
---

SmartStylist is a SwiftUI iOS 17+ app. It runs on the **iOS Simulator** (macOS + Xcode required — not available on Linux). The driver is `smoke.sh`, which builds with `xcodebuild`, installs on the simulator, launches the app, and takes a screenshot.

**Requires macOS with Xcode 16+ installed.**

## Prerequisites

```bash
brew install xcodegen
```

`APIKeys.swift` must exist at `SmartStylist/Config/APIKeys.swift`. The smoke script creates a stub automatically (empty keys — the app UI launches fine; AI and weather calls fail gracefully).

## Build + launch (agent path)

Run from the repo root:

```bash
bash .claude/skills/run-smartstylist/smoke.sh [/path/to/screenshot.png]
```

Default screenshot path: `/tmp/smartstylist_screenshot.png`

The script:
1. Creates stub `APIKeys.swift` if missing
2. Runs `xcodegen generate`
3. Builds Debug for `iphonesimulator` into a temp `DerivedData` dir
4. Boots an iPhone 16 simulator (uses first available if iPhone 16 is absent)
5. Installs + launches `com.rubenaparicio.SmartStylist`
6. Waits 3 s for the first frame, then screenshots via `xcrun simctl io ... screenshot`

Read the screenshot after the script exits to verify the UI.

## What you'll see on first launch

On a clean simulator (no persisted SwiftData store), the app shows **OnboardingContainerView** — the skin-tone / hair / body-type setup flow. Once onboarding is completed and `UserProfile.onboardingCompleted = true`, subsequent launches show **MainTabView** (Closet, Style Engine, Insights, Profile tabs).

## Manual build steps (human path)

```bash
cp SmartStylist/Config/APIKeys.swift.template SmartStylist/Config/APIKeys.swift
# fill in real keys if you want live AI/weather
xcodegen generate
open SmartStylist.xcodeproj   # then ▶ in Xcode
```

## Gotchas

- **Code signing must be disabled for simulator builds.** `smoke.sh` passes `CODE_SIGNING_ALLOWED=NO`. Without it, `xcodebuild` tries to sign with the distribution identity and fails in headless environments.
- **`APIKeys.swift` is gitignored.** The template at `APIKeys.swift.template` has no `.swift` extension so XcodeGen ignores it. The real file must be created manually — or the smoke script creates an empty stub.
- **`Info.plist` is owned by XcodeGen.** Any direct edit to `SmartStylist/Info.plist` is silently overwritten on the next `xcodegen generate`. All Info.plist keys live in `project.yml` under `targets.SmartStylist.info.properties`.
- **Simulator name fallback.** If "iPhone 16" isn't available (older Xcode), the script will fail to find the UDID and print a list of available simulators. Pick one and pass it explicitly, or use `xcrun simctl list devices available | grep iPhone` to find one.
- **`xcodegen` not on PATH.** The CI installs it via `brew install xcodegen`. On a clean machine, run that first.

## Troubleshooting

| Symptom | Fix |
|---------|-----|
| `error: No such module 'SwiftData'` | Xcode version too old — needs Xcode 15+. Run `xcodebuild -version` and update. |
| `Build FAILED` with signing error | Ensure `CODE_SIGNING_ALLOWED=NO` is passed to `xcodebuild`. |
| `xcrun: error: unable to find utility "simctl"` | Xcode command-line tools not set: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` |
| Screenshot is a gray/black screen | App is still launching. Increase the `sleep 3` to `sleep 5` in `smoke.sh`. |
| `App 'com.rubenaparicio.SmartStylist' is not installed` | Build step found no `.app` bundle — check for build errors above in the output. |
