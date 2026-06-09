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

    var displayName: String {
        switch self {
        case .base:  return "Base"
        case .inner: return "Inner"
        case .mid:   return "Mid"
        case .outer: return "Outer"
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
    @Attribute(.unique) var id: UUID
    var imagePath: String?
    var category: ClothingCategory
    // Optional so SwiftData can migrate existing stores that predate this field.
    var thermalLayer: ThermalLayer?
    var primaryColor: String
    var pattern: String
    var style: String
    var tags: [String]
    var status: ItemStatus
    var createdAt: Date
    var disposeReason: String

    // Non-optional accessor; falls back to the category default for migrated records.
    var resolvedThermalLayer: ThermalLayer { thermalLayer ?? category.defaultThermalLayer }

    init(id: UUID = UUID(),
         imagePath: String? = nil,
         category: ClothingCategory,
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
