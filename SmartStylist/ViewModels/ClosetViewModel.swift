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
        case .wornOut:  return "Worn Out"
        case .damaged:  return "Damaged"
        case .donated:  return "Donated"
        case .unused:   return "No Longer Used"
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
    var searchText = ""
    var isAddingItem = false

    // Active + archived — disposed items are permanently excluded
    func visibleItems(from all: [ClothingItem]) -> [ClothingItem] {
        all.filter { $0.status != .disposed }
    }

    // Active only — used by StyleEngine to build outfit recommendations
    func activeItems(from all: [ClothingItem]) -> [ClothingItem] {
        all.filter { $0.status == .active }
    }

    func filteredItems(from all: [ClothingItem]) -> [ClothingItem] {
        let visible = visibleItems(from: all)
        let categoryFiltered = selectedCategory == nil
            ? visible
            : visible.filter { $0.category == selectedCategory }
        guard !searchText.isEmpty else { return categoryFiltered }
        return categoryFiltered.filter {
            $0.tags.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ||
            $0.style.localizedCaseInsensitiveContains(searchText) ||
            $0.primaryColor.localizedCaseInsensitiveContains(searchText)
        }
    }

    func disposeItem(_ item: ClothingItem, reason: DisposeReason = .unused, context: ModelContext) {
        item.status = .disposed
        item.disposeReason = reason.rawValue
        try? context.save()
    }

    func archiveItem(_ item: ClothingItem, context: ModelContext) {
        item.status = .archived
        try? context.save()
    }

    func restoreItem(_ item: ClothingItem, context: ModelContext) {
        item.status = .active
        try? context.save()
    }

    func itemsByCategory(from all: [ClothingItem]) -> [(ClothingCategory, [ClothingItem])] {
        ClothingCategory.allCases.compactMap { cat in
            let items = filteredItems(from: all).filter { $0.category == cat }
            return items.isEmpty ? nil : (cat, items)
        }
    }
}
