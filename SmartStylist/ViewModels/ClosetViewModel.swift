import Foundation
import SwiftData
import Observation

// ── Disposal reason ───────────────────────────────────────────────────────────

enum DisposeReason: String, CaseIterable {
    case wornOut  = "worn"
    case damaged  = "damaged"
    case donated  = "donated"
    case unused   = "unused"

    var label: String {
        switch self {
        case .wornOut:  return Strings.disposeReasonWorn
        case .damaged:  return Strings.disposeReasonDamaged
        case .donated:  return Strings.disposeReasonDonated
        case .unused:   return Strings.disposeReasonUnused
        }
    }

    var icon: String {
        switch self {
        case .wornOut:  return "tshirt"
        case .damaged:  return "exclamationmark.triangle"
        case .donated:  return "heart"
        case .unused:   return "archivebox"
        }
    }
}

// ── View model ────────────────────────────────────────────────────────────────

@Observable
final class ClosetViewModel {
    var selectedCategory: ClothingCategory? = nil
    var searchText = ""          // bound to TextField — updates immediately
    var debouncedSearchText = "" // used by filter predicates — updated after 300ms
    var isAddingItem = false

    // Panel-level filters (drive badge dot on filter button)
    var selectedStyles: Set<String> = []
    var selectedPattern: String? = nil
    var showOnlyStatus: ItemStatus? = nil

    // Canonical style and pattern values — must match ValidationWorkspaceSheet options
    static let knownStyles: [String]   = ["Casual", "Formal", "Smart Casual", "Athletic", "Evening"]
    static let knownPatterns: [String] = ["Solid", "Stripes", "Checks", "Floral", "Abstract", "Animal Print"]

    var hasActiveFilters: Bool {
        !selectedStyles.isEmpty || selectedPattern != nil || showOnlyStatus != nil
    }

    func clearFilters() {
        selectedStyles = []
        selectedPattern = nil
        showOnlyStatus = nil
        selectedCategory = nil
        searchText = ""
        debouncedSearchText = ""
    }

    // Active + archived — disposed items are permanently excluded
    func visibleItems(from all: [ClothingItem]) -> [ClothingItem] {
        all.filter { $0.status != .disposed }
    }

    // Active only — used by StyleEngine to build outfit recommendations
    func activeItems(from all: [ClothingItem]) -> [ClothingItem] {
        all.filter { $0.status == .active }
    }

    func filteredItems(from all: [ClothingItem]) -> [ClothingItem] {
        visibleItems(from: all)
            .filter(statusMatches)
            .filter(categoryMatches)
            .filter(styleMatches)
            .filter(patternMatches)
            .filter(textMatches)
    }

    func disposeItem(_ item: ClothingItem, reason: DisposeReason = .unused, context: ModelContext) {
        item.status = .disposed
        item.disposeReason = reason.rawValue
        // Evict from image cache so stale image memory is freed immediately.
        if let url = item.resolvedImageURL {
            Task { await ImageLoader.shared.evict(url: url) }
        }
        save(context: context, operation: "disposeItem")
    }

    func archiveItem(_ item: ClothingItem, context: ModelContext) {
        item.status = .archived
        save(context: context, operation: "archiveItem")
    }

    func restoreItem(_ item: ClothingItem, context: ModelContext) {
        item.status = .active
        save(context: context, operation: "restoreItem")
    }

    private func save(context: ModelContext, operation: String) {
        do {
            try context.save()
        } catch {
            Task { await DebugLogger.shared.log("\(operation) save failed: \(error.localizedDescription)") }
        }
    }

    func itemsByCategory(from all: [ClothingItem]) -> [(ClothingCategory, [ClothingItem])] {
        ClothingCategory.allCases.compactMap { cat in
            let items = filteredItems(from: all).filter { $0.category == cat }
            return items.isEmpty ? nil : (cat, items)
        }
    }

    // ── Filter predicates ─────────────────────────────────────────────────────

    private func statusMatches(_ item: ClothingItem) -> Bool {
        guard let s = showOnlyStatus else { return true }
        return item.status == s
    }

    private func categoryMatches(_ item: ClothingItem) -> Bool {
        guard let cat = selectedCategory else { return true }
        return item.category == cat
    }

    private func styleMatches(_ item: ClothingItem) -> Bool {
        guard !selectedStyles.isEmpty else { return true }
        return selectedStyles.contains(item.style)
    }

    private func patternMatches(_ item: ClothingItem) -> Bool {
        guard let pattern = selectedPattern else { return true }
        return item.pattern.localizedCaseInsensitiveContains(pattern)
    }

    // Searches: category raw value (Spanish), primary color hex, style, and individual tags.
    // Uses debouncedSearchText to avoid filtering on every keystroke.
    private func textMatches(_ item: ClothingItem) -> Bool {
        guard !debouncedSearchText.isEmpty else { return true }
        let q = debouncedSearchText
        return item.category.rawValue.localizedCaseInsensitiveContains(q)
            || item.primaryColor.localizedCaseInsensitiveContains(q)
            || item.style.localizedCaseInsensitiveContains(q)
            || item.tags.contains { $0.localizedCaseInsensitiveContains(q) }
    }
}
