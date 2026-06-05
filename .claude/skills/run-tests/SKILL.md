---
name: run-tests
description: Build and run the XCTest suite on iPhone simulator. Use when the user asks to run tests, check test results, or verify code changes.
disable-model-invocation: true
---

Run the SmartStylist test suite on the iPhone simulator.

Steps:
1. Generate the Xcode project: `xcodegen generate`
2. Run tests:
```
xcodebuild test \
  -project SmartStylist.xcodeproj \
  -scheme SmartStylist \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -resultBundlePath TestResults.xcresult \
  | xcpretty || xcodebuild test \
  -project SmartStylist.xcodeproj \
  -scheme SmartStylist \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

Report:
- Total tests run
- Pass/fail count
- Any failures with file name, line number, and failure message
- If build fails before tests, report the compiler error
