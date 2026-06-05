import Foundation
import SwiftData

enum ItemStatus: String, Codable, CaseIterable {
    case active    = "active"
    case archived  = "archived"
    case disposed  = "disposed"
}

enum ClothingCategory: String, Codable, CaseIterable {
    case top        = "superior"
    case bottom     = "inferior"
    case footwear   = "calzado"
    case outerwear  = "abrigo"
    case accessory  = "accesorio"
}

@Model
final class ClothingItem {
    @Attribute(.unique) var id: UUID
    var imagePath: String?
    var category: ClothingCategory
    var primaryColor: String
    var pattern: String
    var style: String
    var tags: [String]
    var status: ItemStatus
    var createdAt: Date
    var disposeReason: String

    init(id: UUID = UUID(),
         imagePath: String? = nil,
         category: ClothingCategory,
         primaryColor: String = "#000000",
         pattern: String = "Solid",
         style: String = "Casual",
         tags: [String] = [],
         status: ItemStatus = .active,
         createdAt: Date = Date(),
         disposeReason: String = "") {
        self.id = id
        self.imagePath = imagePath
        self.category = category
        self.primaryColor = primaryColor
        self.pattern = pattern
        self.style = style
        self.tags = tags
        self.status = status
        self.createdAt = createdAt
        self.disposeReason = disposeReason
    }
}
