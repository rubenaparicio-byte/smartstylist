import XCTest
@testable import SmartStylist

final class ClosetViewModelTests: XCTestCase {
    var vm: ClosetViewModel!

    override func setUp() { vm = ClosetViewModel() }

    private func makeItem(status: ItemStatus, category: ClothingCategory = .top) -> ClothingItem {
        ClothingItem(category: category, status: status)
    }

    func test_activeItems_excludesDisposed() {
        let items = [makeItem(status: .active),
                     makeItem(status: .disposed),
                     makeItem(status: .archived)]
        let result = vm.activeItems(from: items)
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.status, .active)
    }

    func test_activeItems_excludesArchived() {
        let items = [makeItem(status: .active), makeItem(status: .archived)]
        XCTAssertEqual(vm.activeItems(from: items).count, 1)
    }

    func test_filteredItems_byCategoryFiltersCorrectly() {
        let items = [makeItem(status: .active, category: .top),
                     makeItem(status: .active, category: .bottom),
                     makeItem(status: .active, category: .footwear)]
        vm.selectedCategory = .top
        XCTAssertEqual(vm.filteredItems(from: items).count, 1)
    }

    func test_filteredItems_nilCategoryReturnsAll() {
        let items = [makeItem(status: .active), makeItem(status: .active)]
        vm.selectedCategory = nil
        XCTAssertEqual(vm.filteredItems(from: items).count, 2)
    }

    func test_itemsByCategory_groupsCorrectly() {
        let items = [makeItem(status: .active, category: .top),
                     makeItem(status: .active, category: .top),
                     makeItem(status: .active, category: .footwear)]
        let groups = vm.itemsByCategory(from: items)
        let topGroup = groups.first(where: { $0.0 == .top })
        XCTAssertEqual(topGroup?.1.count, 2)
    }
}
