import XCTest
@testable import SmartStylist

final class ClosetViewModelTests: XCTestCase {
    var vm: ClosetViewModel!

    override func setUp() { vm = ClosetViewModel() }

    private func makeItem(status: ItemStatus, category: ClothingCategory = .top) -> ClothingItem {
        ClothingItem(category: category, status: status)
    }

    // ── activeItems ───────────────────────────────────────────────────────────

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

    // ── visibleItems ──────────────────────────────────────────────────────────

    func test_visibleItems_excludesDisposed() {
        let items = [makeItem(status: .active),
                     makeItem(status: .archived),
                     makeItem(status: .disposed)]
        let result = vm.visibleItems(from: items)
        XCTAssertEqual(result.count, 2)
        XCTAssertFalse(result.contains { $0.status == .disposed })
    }

    func test_visibleItems_includesActive() {
        let items = [makeItem(status: .active), makeItem(status: .disposed)]
        XCTAssertEqual(vm.visibleItems(from: items).count, 1)
        XCTAssertEqual(vm.visibleItems(from: items).first?.status, .active)
    }

    func test_visibleItems_includesArchived() {
        let items = [makeItem(status: .archived), makeItem(status: .disposed)]
        XCTAssertEqual(vm.visibleItems(from: items).count, 1)
        XCTAssertEqual(vm.visibleItems(from: items).first?.status, .archived)
    }

    func test_visibleItems_emptyWhenAllDisposed() {
        let items = [makeItem(status: .disposed), makeItem(status: .disposed)]
        XCTAssertTrue(vm.visibleItems(from: items).isEmpty)
    }

    // ── filteredItems ─────────────────────────────────────────────────────────

    func test_filteredItems_includesArchivedByDefault() {
        let items = [makeItem(status: .active),
                     makeItem(status: .archived),
                     makeItem(status: .disposed)]
        vm.selectedCategory = nil
        let result = vm.filteredItems(from: items)
        XCTAssertEqual(result.count, 2)
        XCTAssertFalse(result.contains { $0.status == .disposed })
    }

    func test_filteredItems_byCategoryFiltersCorrectly() {
        let items = [makeItem(status: .active, category: .top),
                     makeItem(status: .active, category: .bottom),
                     makeItem(status: .active, category: .footwear)]
        vm.selectedCategory = .top
        XCTAssertEqual(vm.filteredItems(from: items).count, 1)
    }

    func test_filteredItems_nilCategoryReturnsAllVisible() {
        let items = [makeItem(status: .active),
                     makeItem(status: .archived),
                     makeItem(status: .disposed)]
        vm.selectedCategory = nil
        XCTAssertEqual(vm.filteredItems(from: items).count, 2)
    }

    // ── disposeItem ───────────────────────────────────────────────────────────

    func test_disposeItem_setsStatusToDisposed() {
        let item = makeItem(status: .active)
        item.status = .disposed
        item.disposeReason = DisposeReason.damaged.rawValue
        XCTAssertEqual(item.status, .disposed)
        XCTAssertEqual(item.disposeReason, "damaged")
    }

    func test_disposeItem_disposedItemNeverAppearsInVisible() {
        let item = makeItem(status: .active)
        item.status = .disposed
        XCTAssertTrue(vm.visibleItems(from: [item]).isEmpty)
    }

    func test_disposeItem_disposedItemNeverAppearsInActive() {
        let item = makeItem(status: .active)
        item.status = .disposed
        XCTAssertTrue(vm.activeItems(from: [item]).isEmpty)
    }

    // ── archive / restore ─────────────────────────────────────────────────────

    func test_archiveItem_setsStatusToArchived() {
        let item = makeItem(status: .active)
        item.status = .archived
        XCTAssertEqual(item.status, .archived)
    }

    func test_restoreItem_setsStatusToActive() {
        let item = makeItem(status: .archived)
        item.status = .active
        XCTAssertEqual(item.status, .active)
    }

    // ── itemsByCategory ───────────────────────────────────────────────────────

    func test_itemsByCategory_groupsCorrectly() {
        let items = [makeItem(status: .active, category: .top),
                     makeItem(status: .active, category: .top),
                     makeItem(status: .active, category: .footwear)]
        let groups = vm.itemsByCategory(from: items)
        let topGroup = groups.first(where: { $0.0 == .top })
        XCTAssertEqual(topGroup?.1.count, 2)
    }

    func test_itemsByCategory_excludesDisposed() {
        let items = [makeItem(status: .disposed, category: .top),
                     makeItem(status: .active,   category: .top)]
        let groups = vm.itemsByCategory(from: items)
        let topGroup = groups.first(where: { $0.0 == .top })
        XCTAssertEqual(topGroup?.1.count, 1)
    }
}
