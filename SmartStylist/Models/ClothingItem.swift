import Foundation
import SwiftData

// ── ThermalLayer ──────────────────────────────────────────────────────────────

enum ThermalLayer: String, Codable, CaseIterable {
    case base  = "base"
    case inner = "inner"
    case mid   = "mid"
    case outer = "outer"

    var layerNumber: Int {
        switch self {
        case .base:  return 1
        case .inner: return 2
        case .mid:   return 3
        case .outer: return 4
        }
    }

    var localizedName: String {
        switch self {
        case .base:  return String(localized: "layer.base",  locale: Strings.activeLocale)
        case .inner: return String(localized: "layer.inner", locale: Strings.activeLocale)
        case .mid:   return String(localized: "layer.mid",   locale: Strings.activeLocale)
        case .outer: return String(localized: "layer.outer", locale: Strings.activeLocale)
        }
    }

    // SF Symbol conveying thermal position
    var icon: String {
        switch self {
        case .base:  return "figure.stand"
        case .inner: return "tshirt"
        case .mid:   return "cloud"
        case .outer: return "wind"
        }
    }
}

// ── ItemStatus ────────────────────────────────────────────────────────────────

enum ItemStatus: String, Codable, CaseIterable {
    case active    = "active"
    case archived  = "archived"
    case disposed  = "disposed"
}

// ── ClothingCategory ──────────────────────────────────────────────────────────

enum ClothingCategory: String, Codable, CaseIterable {
    case top        = "superior"
    case bottom     = "inferior"
    case footwear   = "calzado"
    case outerwear  = "abrigo"
    case accessory  = "accesorio"

    // Sensible default layer for each category; users can override per item.
    var defaultThermalLayer: ThermalLayer {
        switch self {
        case .top:       return .inner
        case .bottom:    return .inner
        case .footwear:  return .base
        case .outerwear: return .outer
        case .accessory: return .mid
        }
    }
}

// ── ClothingItem ──────────────────────────────────────────────────────────────

@Model
final class ClothingItem {
    // @Attribute(.unique) is incompatible with CloudKit — uniqueness is managed via CKRecord.ID.
    var id: UUID = UUID()
    var imagePath: String?
    var category: ClothingCategory = ClothingCategory.top
    var thermalLayer: ThermalLayer?
    var subcategory: ClothingSubcategory?
    var primaryColor: String = "#000000"
    var pattern: String = "Solid"
    var style: String = "Casual"
    var tags: [String] = []
    var status: ItemStatus = ItemStatus.active
    var createdAt: Date = Date.now
    var disposeReason: String = ""

    // Non-optional accessor; falls back to the category default for migrated records.
    var resolvedThermalLayer: ThermalLayer { thermalLayer ?? category.defaultThermalLayer }

    // Resolves the stored path (relative or legacy absolute) to a live URL.
    var resolvedImageURL: URL? {
        guard let path = imagePath else { return nil }
        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path)
        }
        return FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(path)
    }

    init(id: UUID = UUID(),
         imagePath: String? = nil,
         category: ClothingCategory,
         subcategory: ClothingSubcategory? = nil,
         thermalLayer: ThermalLayer? = nil,
         primaryColor: String = "#000000",
         pattern: String = "Solid",
         style: String = "Casual",
         tags: [String] = [],
         status: ItemStatus = .active,
         createdAt: Date = Date(),
         disposeReason: String = "") {
        self.id           = id
        self.imagePath    = imagePath
        self.category     = category
        self.subcategory  = subcategory
        self.thermalLayer = thermalLayer ?? category.defaultThermalLayer
        self.primaryColor = primaryColor
        self.pattern      = pattern
        self.style        = style
        self.tags         = tags
        self.status       = status
        self.createdAt    = createdAt
        self.disposeReason = disposeReason
    }
}
