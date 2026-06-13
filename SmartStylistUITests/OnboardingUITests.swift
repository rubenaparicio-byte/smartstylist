import XCTest

// UI tests launch the app process as a black box.
// The --uitesting launch argument tells the app to:
//   • Skip authentication (show OnboardingContainerView directly)
//   • Use an in-memory SwiftData store (no CloudKit, no persisted state)
// This guarantees a clean, deterministic onboarding flow on every run.

final class OnboardingUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // ── Language step — initial state ─────────────────────────────────────────

    func test_languageStep_showsAllThreeOptions() {
        XCTAssertTrue(app.buttons["language.system"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["language.en"].exists)
        XCTAssertTrue(app.buttons["language.es"].exists)
    }

    func test_languageStep_continueButton_isEnabled() {
        // Language step always allows advancing — System is selected by default.
        XCTAssertTrue(app.buttons["language.en"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["onboarding.advance"].isEnabled)
    }

    func test_languageStep_continueButton_isVisible() {
        XCTAssertTrue(app.buttons["onboarding.advance"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["onboarding.advance"].isHittable)
    }

    // ── Language selection and advance ────────────────────────────────────────

    func test_selectEnglish_advancesToGenderStep() {
        let englishButton = app.buttons["language.en"]
        XCTAssertTrue(englishButton.waitForExistence(timeout: 5))
        englishButton.tap()

        app.buttons["onboarding.advance"].tap()

        // After advancing, the gender cards should be on screen (hittable).
        let maleCard = app.buttons["gender.male"]
        XCTAssertTrue(maleCard.waitForExistence(timeout: 5))
        XCTAssertTrue(maleCard.isHittable)
    }

    func test_selectSystem_advancesToGenderStep() {
        let systemButton = app.buttons["language.system"]
        XCTAssertTrue(systemButton.waitForExistence(timeout: 5))
        systemButton.tap()

        app.buttons["onboarding.advance"].tap()

        XCTAssertTrue(app.buttons["gender.male"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["gender.male"].isHittable)
    }

    func test_selectEspanol_advancesToGenderStep() {
        let esButton = app.buttons["language.es"]
        XCTAssertTrue(esButton.waitForExistence(timeout: 5))
        esButton.tap()

        app.buttons["onboarding.advance"].tap()

        // Gender cards exist regardless of language
        let maleCard = app.buttons["gender.male"]
        XCTAssertTrue(maleCard.waitForExistence(timeout: 5))
        XCTAssertTrue(maleCard.isHittable)
    }

    // ── Gender step — advance gating ──────────────────────────────────────────

    func test_genderStep_continueButton_disabledWithoutSelection() {
        // Navigate to gender step
        XCTAssertTrue(app.buttons["language.en"].waitForExistence(timeout: 5))
        app.buttons["onboarding.advance"].tap()

        let advance = app.buttons["onboarding.advance"]
        XCTAssertTrue(advance.waitForExistence(timeout: 5))
        // Gender step requires a selection before advancing.
        XCTAssertFalse(advance.isEnabled)
    }

    func test_genderStep_selectMale_enablesContinue() {
        // Navigate to gender step
        XCTAssertTrue(app.buttons["language.en"].waitForExistence(timeout: 5))
        app.buttons["onboarding.advance"].tap()

        let maleCard = app.buttons["gender.male"]
        XCTAssertTrue(maleCard.waitForExistence(timeout: 5))
        maleCard.tap()

        XCTAssertTrue(app.buttons["onboarding.advance"].isEnabled)
    }

    func test_genderStep_selectFemale_enablesContinue() {
        XCTAssertTrue(app.buttons["language.en"].waitForExistence(timeout: 5))
        app.buttons["onboarding.advance"].tap()

        let femaleCard = app.buttons["gender.female"]
        XCTAssertTrue(femaleCard.waitForExistence(timeout: 5))
        femaleCard.tap()

        XCTAssertTrue(app.buttons["onboarding.advance"].isEnabled)
    }

    func test_genderStep_bothCards_visible() {
        XCTAssertTrue(app.buttons["language.en"].waitForExistence(timeout: 5))
        app.buttons["onboarding.advance"].tap()

        XCTAssertTrue(app.buttons["gender.male"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["gender.female"].waitForExistence(timeout: 5))
    }
}
