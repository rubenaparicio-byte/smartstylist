import XCTest
import SwiftData
@testable import SmartStylist

// @MainActor: ProfileViewModel is @MainActor-isolated; ModelContext.mainContext requires main actor.
@MainActor
final class ProfileViewModelTests: XCTestCase {
    var container: ModelContainer!
    var vm: ProfileViewModel!

    override func setUp() async throws {
        container = try ModelContainer(
            for: UserProfile.self, ClothingItem.self, OutfitHistory.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        vm = ProfileViewModel()
    }

    override func tearDown() async throws {
        container = nil
        vm = nil
    }

    // ── Initial state ─────────────────────────────────────────────────────────

    func test_showRetakeConfirmation_defaultsFalse() {
        XCTAssertFalse(vm.showRetakeConfirmation)
    }

    func test_showDeleteConfirmation_defaultsFalse() {
        XCTAssertFalse(vm.showDeleteConfirmation)
    }

    // ── retakeAnalysis ────────────────────────────────────────────────────────

    func test_retakeAnalysis_deletesProfile() throws {
        let ctx = container.mainContext
        let profile = UserProfile(bodyType: "Slim", onboardingCompleted: true)
        ctx.insert(profile)
        try ctx.save()

        vm.retakeAnalysis(profile: profile, context: ctx)

        let remaining = try ctx.fetch(FetchDescriptor<UserProfile>())
        XCTAssertTrue(remaining.isEmpty)
    }

    func test_retakeAnalysis_preservesClothingItems() throws {
        let ctx = container.mainContext
        let profile = UserProfile(onboardingCompleted: true)
        let item = ClothingItem(category: .top)
        ctx.insert(profile)
        ctx.insert(item)
        try ctx.save()

        vm.retakeAnalysis(profile: profile, context: ctx)

        let remainingItems = try ctx.fetch(FetchDescriptor<ClothingItem>())
        XCTAssertEqual(remainingItems.count, 1)
    }

    // ── deleteAllData ─────────────────────────────────────────────────────────

    func test_deleteAllData_removesAllEntities() throws {
        let ctx = container.mainContext
        ctx.insert(UserProfile())
        ctx.insert(ClothingItem(category: .top))
        ctx.insert(OutfitHistory())
        try ctx.save()

        vm.deleteAllData(context: ctx)

        XCTAssertTrue(try ctx.fetch(FetchDescriptor<UserProfile>()).isEmpty)
        XCTAssertTrue(try ctx.fetch(FetchDescriptor<ClothingItem>()).isEmpty)
        XCTAssertTrue(try ctx.fetch(FetchDescriptor<OutfitHistory>()).isEmpty)
    }

    func test_deleteAllData_worksOnEmptyStore() {
        XCTAssertNoThrow(vm.deleteAllData(context: container.mainContext))
    }

    func test_deleteAllData_removesMultipleProfiles() throws {
        let ctx = container.mainContext
        ctx.insert(UserProfile())
        ctx.insert(UserProfile())
        try ctx.save()

        vm.deleteAllData(context: ctx)

        XCTAssertTrue(try ctx.fetch(FetchDescriptor<UserProfile>()).isEmpty)
    }
}
