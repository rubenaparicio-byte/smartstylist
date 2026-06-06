import XCTest
@testable import SmartStylist

final class InsightsViewModelTests: XCTestCase {
    var vm: InsightsViewModel!

    override func setUp() { vm = InsightsViewModel() }

    // Helper that creates a standalone ClothingItem (no ModelContext required)
    private func makeItem(
        status: ItemStatus = .active,
        style: String = "Casual",
        category: ClothingCategory = .top
    ) -> ClothingItem {
        ClothingItem(category: category, style: style, status: status)
    }

    // ── styleDistribution ─────────────────────────────────────────────────────

    func test_styleDistribution_returnsCorrectCounts() {
        let items = [makeItem(style: "Casual"),
                     makeItem(style: "Casual"),
                     makeItem(style: "Formal")]
        let dist = vm.styleDistribution(from: items)
        XCTAssertEqual(dist.first { $0.style == "Casual" }?.count, 2)
        XCTAssertEqual(dist.first { $0.style == "Formal" }?.count, 1)
    }

    func test_styleDistribution_excludesDisposed() {
        let items = [makeItem(status: .active, style: "Casual"),
                     makeItem(status: .disposed, style: "Formal")]
        let dist = vm.styleDistribution(from: items)
        XCTAssertEqual(dist.count, 1)
        XCTAssertEqual(dist.first?.style, "Casual")
    }

    func test_styleDistribution_emptyWhenNoItems() {
        XCTAssertTrue(vm.styleDistribution(from: []).isEmpty)
    }

    func test_styleDistribution_sortedByCountDescending() {
        let items = [makeItem(style: "Formal"),
                     makeItem(style: "Casual"),
                     makeItem(style: "Casual"),
                     makeItem(style: "Casual")]
        let dist = vm.styleDistribution(from: items)
        XCTAssertEqual(dist.first?.style, "Casual")
        XCTAssertEqual(dist.last?.style,  "Formal")
    }

    func test_styleDistribution_includesArchived() {
        let items = [makeItem(status: .active,   style: "Casual"),
                     makeItem(status: .archived, style: "Formal")]
        let dist = vm.styleDistribution(from: items)
        XCTAssertEqual(dist.count, 2)
    }

    func test_styleDistribution_assignsChartColors() {
        let dist = vm.styleDistribution(from: [makeItem(style: "Casual")])
        XCTAssertFalse(dist.first!.chartColorHex.isEmpty)
    }

    // ── topWornItems ──────────────────────────────────────────────────────────

    func test_topWornItems_emptyHistoryReturnsEmpty() {
        XCTAssertTrue(vm.topWornItems(from: [makeItem()], history: []).isEmpty)
    }

    func test_topWornItems_returnsAtMost3() {
        let items = (0..<5).map { _ in makeItem() }
        let now   = Date()
        let history = items.map { OutfitHistory(date: now, clothingItemIds: [$0.id]) }
        let result  = vm.topWornItems(from: items, history: history, referenceDate: now)
        XCTAssertLessThanOrEqual(result.count, 3)
    }

    func test_topWornItems_excludesOlderThan30Days() {
        let item = makeItem()
        let oldDate = Calendar.current.date(byAdding: .day, value: -31, to: Date())!
        let old = OutfitHistory(date: oldDate, clothingItemIds: [item.id])
        let result = vm.topWornItems(from: [item], history: [old], referenceDate: Date())
        XCTAssertTrue(result.isEmpty)
    }

    func test_topWornItems_includesExactly30DayBoundary() {
        let item = makeItem()
        let ref  = Date()
        let boundary = Calendar.current.date(byAdding: .day, value: -30, to: ref)!
        let entry = OutfitHistory(date: boundary, clothingItemIds: [item.id])
        let result = vm.topWornItems(from: [item], history: [entry], referenceDate: ref)
        XCTAssertEqual(result.count, 1)
    }

    func test_topWornItems_sortedByWearCountDescending() {
        let item1 = makeItem()
        let item2 = makeItem()
        let now   = Date()
        let history = [
            OutfitHistory(date: now, clothingItemIds: [item2.id]),
            OutfitHistory(date: now, clothingItemIds: [item2.id]),
            OutfitHistory(date: now, clothingItemIds: [item1.id])
        ]
        let result = vm.topWornItems(from: [item1, item2], history: history, referenceDate: now)
        XCTAssertEqual(result.first?.item.id, item2.id)
        XCTAssertEqual(result.first?.wearCount, 2)
    }

    func test_topWornItems_excludesDisposedItems() {
        let active   = makeItem(status: .active)
        let disposed = makeItem(status: .disposed)
        let now      = Date()
        let history  = [OutfitHistory(date: now, clothingItemIds: [active.id, disposed.id])]
        let result   = vm.topWornItems(from: [active, disposed], history: history, referenceDate: now)
        XCTAssertFalse(result.contains { $0.item.id == disposed.id })
    }

    // ── closetHealth ──────────────────────────────────────────────────────────

    func test_closetHealth_countsStatuses() {
        let items = [makeItem(status: .active),
                     makeItem(status: .active),
                     makeItem(status: .archived),
                     makeItem(status: .disposed)]
        let h = vm.closetHealth(from: items)
        XCTAssertEqual(h.active,   2)
        XCTAssertEqual(h.archived, 1)
        XCTAssertEqual(h.disposed, 1)
        XCTAssertEqual(h.total,    4)
    }

    func test_closetHealth_emptyReturnsZeros() {
        let h = vm.closetHealth(from: [])
        XCTAssertEqual(h.active,   0)
        XCTAssertEqual(h.archived, 0)
        XCTAssertEqual(h.disposed, 0)
        XCTAssertNil(h.topDisposeReason)
    }

    func test_closetHealth_topDisposeReason() {
        let d1 = ClothingItem(category: .top, status: .disposed)
        d1.disposeReason = "donated"
        let d2 = ClothingItem(category: .top, status: .disposed)
        d2.disposeReason = "donated"
        let d3 = ClothingItem(category: .top, status: .disposed)
        d3.disposeReason = "worn"

        let h = vm.closetHealth(from: [d1, d2, d3])
        XCTAssertEqual(h.topDisposeReason, "donated")
    }

    func test_closetHealth_nilDisposeReasonWhenNoneDisposed() {
        let h = vm.closetHealth(from: [makeItem(status: .active)])
        XCTAssertNil(h.topDisposeReason)
    }

    func test_closetHealth_percentagesAreCorrect() {
        let items = [makeItem(status: .active),
                     makeItem(status: .active),
                     makeItem(status: .archived)]
        let h = vm.closetHealth(from: items)
        XCTAssertEqual(h.activePercent, 2.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(h.archivedPercent, 1.0 / 3.0, accuracy: 0.001)
        XCTAssertEqual(h.disposedPercent, 0.0, accuracy: 0.001)
    }
}
