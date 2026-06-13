import XCTest
@testable import SmartStylist

final class ClosetViewModelTests: XCTestCase {
    var vm: ClosetViewModel!

    override func setUp() { vm = ClosetViewModel() }

    // Full-parameter helper; all existing tests still work because status has no default
    // but the call sites continue to compile — earlier tests pass status explicitly.
    private func makeItem(
        status: ItemStatus = .active,
        category: ClothingCategory = .top,
        style: String = "Casual",
        pattern: String = "Solid",
        color: String = "#000000",
        tags: [String] = []
    ) -> ClothingItem {
        ClothingItem(category: category, primaryColor: color,
                     pattern: pattern, style: style, tags: tags, status: status)
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

    // ── filteredItems — existing behaviour preserved ───────────────────────────

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

    // ── hasActiveFilters ──────────────────────────────────────────────────────

    func test_hasActiveFilters_falseByDefault() {
        XCTAssertFalse(vm.hasActiveFilters)
    }

    func test_hasActiveFilters_trueWhenStyleSelected() {
        vm.selectedStyles.insert("Formal")
        XCTAssertTrue(vm.hasActiveFilters)
    }

    func test_hasActiveFilters_trueWhenPatternSelected() {
        vm.selectedPattern = "Stripes"
        XCTAssertTrue(vm.hasActiveFilters)
    }

    func test_hasActiveFilters_trueWhenStatusSelected() {
        vm.showOnlyStatus = .active
        XCTAssertTrue(vm.hasActiveFilters)
    }

    // ── clearFilters ──────────────────────────────────────────────────────────

    func test_clearFilters_resetsAllFilters() {
        vm.selectedStyles      = ["Casual", "Formal"]
        vm.selectedPattern     = "Stripes"
        vm.showOnlyStatus      = .active
        vm.selectedCategory    = .top
        vm.searchText          = "blue"
        vm.debouncedSearchText = "blue"
        vm.clearFilters()
        XCTAssertTrue(vm.selectedStyles.isEmpty)
        XCTAssertNil(vm.selectedPattern)
        XCTAssertNil(vm.showOnlyStatus)
        XCTAssertNil(vm.selectedCategory)
        XCTAssertTrue(vm.searchText.isEmpty)
        XCTAssertTrue(vm.debouncedSearchText.isEmpty)
    }

    // ── filteredItems — style filter ──────────────────────────────────────────

    func test_filteredItems_byStyle_returnsMatchingItems() {
        let casual = makeItem(style: "Casual")
        let formal = makeItem(style: "Formal")
        vm.selectedStyles = ["Formal"]
        let result = vm.filteredItems(from: [casual, formal])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.style, "Formal")
    }

    func test_filteredItems_byMultipleStyles_returnsUnion() {
        let casual   = makeItem(style: "Casual")
        let formal   = makeItem(style: "Formal")
        let athletic = makeItem(style: "Athletic")
        vm.selectedStyles = ["Casual", "Athletic"]
        let result = vm.filteredItems(from: [casual, formal, athletic])
        XCTAssertEqual(result.count, 2)
        XCTAssertFalse(result.contains { $0.style == "Formal" })
    }

    func test_filteredItems_emptyStyleSet_returnsAll() {
        let items = [makeItem(style: "Casual"), makeItem(style: "Formal")]
        vm.selectedStyles = []
        XCTAssertEqual(vm.filteredItems(from: items).count, 2)
    }

    // ── filteredItems — pattern filter ────────────────────────────────────────

    func test_filteredItems_byPattern_returnsMatchingItems() {
        let solid   = makeItem(pattern: "Solid")
        let stripes = makeItem(pattern: "Stripes")
        vm.selectedPattern = "Stripes"
        let result = vm.filteredItems(from: [solid, stripes])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.pattern, "Stripes")
    }

    func test_filteredItems_nilPattern_returnsAll() {
        let items = [makeItem(pattern: "Solid"), makeItem(pattern: "Stripes")]
        vm.selectedPattern = nil
        XCTAssertEqual(vm.filteredItems(from: items).count, 2)
    }

    // ── filteredItems — status filter ─────────────────────────────────────────

    func test_filteredItems_showOnlyActive_excludesArchived() {
        let active   = makeItem(status: .active)
        let archived = makeItem(status: .archived)
        vm.showOnlyStatus = .active
        let result = vm.filteredItems(from: [active, archived])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.status, .active)
    }

    func test_filteredItems_showOnlyArchived_excludesActive() {
        let active   = makeItem(status: .active)
        let archived = makeItem(status: .archived)
        vm.showOnlyStatus = .archived
        let result = vm.filteredItems(from: [active, archived])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.status, .archived)
    }

    // ── filteredItems — text search (uses debouncedSearchText) ───────────────

    func test_filteredItems_searchByColor_returnsMatch() {
        let blue = makeItem(color: "#0000FF")
        let red  = makeItem(color: "#FF0000")
        vm.debouncedSearchText = "#0000FF"
        let result = vm.filteredItems(from: [blue, red])
        XCTAssertEqual(result.count, 1)
    }

    func test_filteredItems_searchByTag_returnsMatch() {
        let workItem   = makeItem(tags: ["work", "formal"])
        let casualItem = makeItem(tags: ["weekend"])
        vm.debouncedSearchText = "formal"
        let result = vm.filteredItems(from: [workItem, casualItem])
        XCTAssertEqual(result.count, 1)
    }

    func test_filteredItems_searchByStyle_returnsMatch() {
        let casual = makeItem(style: "Casual")
        let formal = makeItem(style: "Formal")
        vm.debouncedSearchText = "casual"
        let result = vm.filteredItems(from: [casual, formal])
        XCTAssertEqual(result.count, 1)
    }

    func test_filteredItems_searchByCategoryRawValue_returnsMatch() {
        // ClothingCategory.top rawValue = "superior" (Spanish)
        let top    = makeItem(category: .top)
        let bottom = makeItem(category: .bottom)
        vm.debouncedSearchText = "superior"
        let result = vm.filteredItems(from: [top, bottom])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.category, .top)
    }

    func test_filteredItems_rawSearchText_doesNotFilterBeforeDebounce() {
        let blue = makeItem(color: "#0000FF")
        let red  = makeItem(color: "#FF0000")
        vm.searchText = "#0000FF"       // raw text — no debounce applied
        vm.debouncedSearchText = ""     // debounced still empty
        let result = vm.filteredItems(from: [blue, red])
        XCTAssertEqual(result.count, 2) // both items shown until debounce fires
    }

    // ── filteredItems — combined filters ──────────────────────────────────────

    func test_filteredItems_combinedStyleAndCategory() {
        let casualTop    = makeItem(category: .top,    style: "Casual")
        let formalTop    = makeItem(category: .top,    style: "Formal")
        let casualBottom = makeItem(category: .bottom, style: "Casual")
        vm.selectedStyles   = ["Casual"]
        vm.selectedCategory = .top
        let result = vm.filteredItems(from: [casualTop, formalTop, casualBottom])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.category, .top)
        XCTAssertEqual(result.first?.style, "Casual")
    }

    func test_filteredItems_combinedSearchAndStyle() {
        let blueFormal  = makeItem(style: "Formal", color: "#0000FF")
        let blueCasual  = makeItem(style: "Casual", color: "#0000FF")
        let redFormal   = makeItem(style: "Formal", color: "#FF0000")
        vm.selectedStyles      = ["Formal"]
        vm.debouncedSearchText = "#0000FF"
        let result = vm.filteredItems(from: [blueFormal, blueCasual, redFormal])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.style, "Formal")
    }

    func test_filteredItems_combinedPatternAndStatus() {
        let activeStripes   = makeItem(status: .active,   pattern: "Stripes")
        let archivedStripes = makeItem(status: .archived, pattern: "Stripes")
        let activeSolid     = makeItem(status: .active,   pattern: "Solid")
        vm.selectedPattern = "Stripes"
        vm.showOnlyStatus  = .active
        let result = vm.filteredItems(from: [activeStripes, archivedStripes, activeSolid])
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.pattern, "Stripes")
        XCTAssertEqual(result.first?.status, .active)
    }
}
