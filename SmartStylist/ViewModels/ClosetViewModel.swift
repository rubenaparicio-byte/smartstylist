import Foundation
import SwiftData
import Observation

@Observable
final class ClosetViewModel {
    var selectedCategory: ClothingCategory? = nil
    var searchText = ""
    var isAddingItem = false

    func activeItems(from all: [ClothingItem]) -> [ClothingItem] {
        all.filter { $0.status == .active }
    }

    func filteredItems(from all: [ClothingItem]) -> [ClothingItem] {
        let active = activeItems(from: all)
        let categoryFiltered = selectedCategory == nil
            ? active
            : active.filter { $0.category == selectedCategory }
        guard !searchText.isEmpty else { return categoryFiltered }
        return categoryFiltered.filter {
            $0.tags.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ||
            $0.style.localizedCaseInsensitiveContains(searchText) ||
            $0.primaryColor.localizedCaseInsensitiveContains(searchText)
        }
    }

    func disposeItem(_ item: ClothingItem, context: ModelContext) {
        item.status = .disposed
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
