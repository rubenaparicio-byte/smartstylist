---
name: new-test
description: Generate an XCTest file for a given subject (Model, Service, or ViewModel) following SmartStylist test conventions.
---

Generate a test file for: $ARGUMENTS

## Conventions to follow

**File placement**: Match the folder of the subject being tested:
- `SmartStylistTests/Models/` for @Model types
- `SmartStylistTests/Services/` for Service classes
- `SmartStylistTests/ViewModels/` for @Observable ViewModels

**File naming**: `<SubjectName>Tests.swift`

**Test naming**: `test_<subject>_<condition>_<expectation>`
- Example: `test_closetViewModel_whenFilteredByCategory_returnsOnlyMatchingItems`

**Boilerplate structure**:
```swift
import XCTest
import SwiftData
@testable import SmartStylist

final class <Subject>Tests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!

    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: /* relevant models */, configurations: config)
        context = ModelContext(container)
    }

    override func tearDown() async throws {
        container = nil
        context = nil
    }

    // MARK: - Tests
}
```

**Rules**:
- Always use in-memory `ModelContainer` — never write to disk in tests
- Mock network services with local JSON fixtures or protocol stubs — never hit real APIs
- Test one behaviour per test function
- Use `XCTAssertEqual`, `XCTAssertTrue`, `XCTAssertNil` — no third-party assertion libraries
- Async tests use `async throws` and `await`

Create the file and add at least 3 representative test cases covering happy path, edge case, and failure/empty state.
