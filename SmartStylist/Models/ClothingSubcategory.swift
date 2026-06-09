import Foundation

// ── ClothingSubcategory ───────────────────────────────────────────────────────
// Two-level taxonomy: ClothingCategory (broad, drives ThermalLayer logic) +
// ClothingSubcategory (specific, gives the LLM richer context per item).

enum ClothingSubcategory: String, Codable, CaseIterable {

    // Tops
    case tshirt     = "tshirt"
    case shirt      = "shirt"
    case sweater    = "sweater"
    case hoodie     = "hoodie"
    case polo       = "polo"
    case blouse     = "blouse"
    case cardigan   = "cardigan"
    case vest       = "vest"
    case bodysuit   = "bodysuit"

    // Bottoms
    case jeans      = "jeans"
    case trousers   = "trousers"
    case shorts     = "shorts"
    case skirt      = "skirt"
    case leggings   = "leggings"
    case joggers    = "joggers"

    // Footwear
    case sneakers   = "sneakers"
    case boots      = "boots"
    case heels      = "heels"
    case sandals    = "sandals"
    case loafers    = "loafers"
    case sportShoes = "sport_shoes"
    case slippers   = "slippers"

    // Outerwear
    case coat       = "coat"
    case jacket     = "jacket"
    case blazer     = "blazer"
    case bomber     = "bomber"
    case raincoat   = "raincoat"
    case puffer     = "puffer"
    case trench     = "trench"

    // Accessories
    case belt       = "belt"
    case scarf      = "scarf"
    case hat        = "hat"
    case sunglasses = "sunglasses"
    case jewelry    = "jewelry"
    case tie        = "tie"
    case gloves     = "gloves"
    case bag        = "bag"
    case backpack   = "backpack"

    var parentCategory: ClothingCategory {
        switch self {
        case .tshirt, .shirt, .sweater, .hoodie, .polo, .blouse, .cardigan, .vest, .bodysuit:
            return .top
        case .jeans, .trousers, .shorts, .skirt, .leggings, .joggers:
            return .bottom
        case .sneakers, .boots, .heels, .sandals, .loafers, .sportShoes, .slippers:
            return .footwear
        case .coat, .jacket, .blazer, .bomber, .raincoat, .puffer, .trench:
            return .outerwear
        case .belt, .scarf, .hat, .sunglasses, .jewelry, .tie, .gloves, .bag, .backpack:
            return .accessory
        }
    }

    var localizedName: String {
        String(localized: .init("subcategory.\(rawValue)"), locale: Strings.activeLocale)
    }
}

extension ClothingCategory {
    var subcategories: [ClothingSubcategory] {
        ClothingSubcategory.allCases.filter { $0.parentCategory == self }
    }
}
