import Foundation
import Observation

// ── InsightsViewModel ─────────────────────────────────────────────────────────
// Pure computation — no SwiftUI, no SwiftData mutations.
// All methods accept arrays so they can be called from @Query results or tests.

@Observable
final class InsightsViewModel {

    // MARK: — Output types

    struct StyleEntry: Identifiable {
        let id = UUID()
        let style: String
        let count: Int
        let chartColorHex: String
    }

    struct TopItem: Identifiable {
        let id = UUID()
        let item: ClothingItem
        let wearCount: Int
    }

    struct HealthSnapshot {
        let active: Int
        let archived: Int
        let disposed: Int
        let topDisposeReason: String?

        var total: Int { active + archived + disposed }
        var activePercent:   Double { total > 0 ? Double(active)   / Double(total) : 0 }
        var archivedPercent: Double { total > 0 ? Double(archived) / Double(total) : 0 }
        var disposedPercent: Double { total > 0 ? Double(disposed) / Double(total) : 0 }
    }

    // Gold/slate palette for chart sectors — hex only (no SwiftUI import needed)
    private static let chartHexes: [String] = [
        "#D4AF37", "#E9C46A", "#A0845C",
        "#C4962A", "#6B5C3E", "#8B7355"
    ]

    // MARK: — Style distribution

    func styleDistribution(from items: [ClothingItem]) -> [StyleEntry] {
        let visible = items.filter { $0.status != .disposed }
        guard !visible.isEmpty else { return [] }
        var counts: [String: Int] = [:]
        for item in visible { counts[item.style, default: 0] += 1 }
        return counts
            .sorted { $0.value > $1.value }
            .enumerated()
            .map { idx, pair in
                StyleEntry(style: pair.key, count: pair.value,
                           chartColorHex: Self.chartHexes[idx % Self.chartHexes.count])
            }
    }

    // MARK: — Top worn items (last 30 days)

    /// referenceDate defaults to Date() — tests inject a fixed value for determinism.
    func topWornItems(
        from items: [ClothingItem],
        history: [OutfitHistory],
        referenceDate: Date = Date()
    ) -> [TopItem] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: referenceDate) ?? referenceDate
        let recent = history.filter { $0.date >= cutoff }

        var countByID: [UUID: Int] = [:]
        for entry in recent {
            for id in entry.clothingItemIds {
                countByID[id, default: 0] += 1
            }
        }

        return items
            .filter { $0.status == .active }
            .compactMap { item -> TopItem? in
                guard let count = countByID[item.id], count > 0 else { return nil }
                return TopItem(item: item, wearCount: count)
            }
            .sorted { $0.wearCount > $1.wearCount }
            .prefix(3)
            .map { $0 }
    }

    // MARK: — Closet health

    func closetHealth(from items: [ClothingItem]) -> HealthSnapshot {
        let active   = items.filter { $0.status == .active }.count
        let archived = items.filter { $0.status == .archived }.count
        let disposed = items.filter { $0.status == .disposed }.count

        var reasonCounts: [String: Int] = [:]
        for item in items where item.status == .disposed && !item.disposeReason.isEmpty {
            reasonCounts[item.disposeReason, default: 0] += 1
        }
        let topReason = reasonCounts.max { $0.value < $1.value }?.key

        return HealthSnapshot(active: active, archived: archived,
                              disposed: disposed, topDisposeReason: topReason)
    }
}
