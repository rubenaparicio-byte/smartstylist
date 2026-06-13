import XCTest
@testable import SmartStylist

final class UserProfileTests: XCTestCase {

    // ── recommendedColorSwatches ──────────────────────────────────────────────

    func test_recommendedColorSwatches_zipsBothArrays() {
        let profile = UserProfile(
            recommendedColorNames: ["Navy", "Ivory", "Camel"],
            recommendedColorHexes: ["#001F5B", "#FFFFF0", "#C19A6B"]
        )
        let swatches: [ColorSwatch] = profile.recommendedColorSwatches
        XCTAssertEqual(swatches.count, 3)
        XCTAssertEqual(swatches[0].name, "Navy")
        XCTAssertEqual(swatches[0].hex,  "#001F5B")
        XCTAssertEqual(swatches[2].name, "Camel")
    }

    func test_recommendedColorSwatches_truncatesToShorterArray() {
        // LLM returns 6 names but only 4 hexes — zip stops at the shorter one.
        let profile = UserProfile(
            recommendedColorNames: ["A", "B", "C", "D", "E", "F"],
            recommendedColorHexes: ["#111", "#222", "#333", "#444"]
        )
        XCTAssertEqual(profile.recommendedColorSwatches.count, 4)
    }

    func test_recommendedColorSwatches_emptyWhenBothEmpty() {
        let profile = UserProfile()
        XCTAssertTrue(profile.recommendedColorSwatches.isEmpty)
    }

    // ── avoidColorSwatches ────────────────────────────────────────────────────

    func test_avoidColorSwatches_zipsBothArrays() {
        let profile = UserProfile(
            avoidColorNames: ["Neon Green", "Orange"],
            avoidColorHexes: ["#39FF14", "#FF6600"]
        )
        let swatches = profile.avoidColorSwatches
        XCTAssertEqual(swatches.count, 2)
        XCTAssertEqual(swatches[1].hex, "#FF6600")
    }

    func test_avoidColorSwatches_doesNotCrashWhenMismatched() {
        let profile = UserProfile(
            avoidColorNames: ["One"],
            avoidColorHexes: []
        )
        // Should not crash — zip returns empty when either is empty.
        XCTAssertTrue(profile.avoidColorSwatches.isEmpty)
    }

    // ── Default values ────────────────────────────────────────────────────────

    func test_defaultInit_hasExpectedDefaults() {
        let profile = UserProfile()
        XCTAssertFalse(profile.onboardingCompleted)
        XCTAssertEqual(profile.metalPreference, "Gold")
        XCTAssertTrue(profile.accessoryStyle.isEmpty)
        XCTAssertTrue(profile.preferredStores.isEmpty)
        XCTAssertNil(profile.age)
        XCTAssertNil(profile.gender)
    }
}
