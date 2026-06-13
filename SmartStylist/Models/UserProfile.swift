import Foundation
import SwiftData

@Model
final class UserProfile {
    // @Attribute(.unique) is incompatible with CloudKit — uniqueness is managed via CKRecord.ID.
    var id: UUID = UUID()
    var gender: String?           // "Male" | "Female" — optional for safe migration
    var bodyType: String = ""
    var skinTone: String = ""
    var eyeColor: String = ""
    var hairColor: String = ""
    var seasonalColorimetry: String = ""
    var styleGuidelines: String = ""
    var onboardingCompleted: Bool = false
    var recommendedColorNames: [String] = []
    var recommendedColorHexes: [String] = []
    var avoidColorNames: [String] = []
    var avoidColorHexes: [String] = []
    var metalPreference: String = "Gold"
    var accessoryStyle: [String] = []   // ["Minimal", "Statement", "Layered", "Vintage"]
    var preferredStores: [String] = []  // brand names the user shops at
    var age: Int?                        // nil = not set

    init(id: UUID = UUID(),
         gender: String? = nil,
         bodyType: String = "",
         skinTone: String = "",
         eyeColor: String = "",
         hairColor: String = "",
         seasonalColorimetry: String = "",
         styleGuidelines: String = "",
         onboardingCompleted: Bool = false,
         recommendedColorNames: [String] = [],
         recommendedColorHexes: [String] = [],
         avoidColorNames: [String] = [],
         avoidColorHexes: [String] = [],
         metalPreference: String = "Gold",
         accessoryStyle: [String] = [],
         preferredStores: [String] = [],
         age: Int? = nil) {
        self.id = id
        self.gender = gender
        self.bodyType = bodyType
        self.skinTone = skinTone
        self.eyeColor = eyeColor
        self.hairColor = hairColor
        self.seasonalColorimetry = seasonalColorimetry
        self.styleGuidelines = styleGuidelines
        self.onboardingCompleted = onboardingCompleted
        self.recommendedColorNames = recommendedColorNames
        self.recommendedColorHexes = recommendedColorHexes
        self.avoidColorNames = avoidColorNames
        self.avoidColorHexes = avoidColorHexes
        self.metalPreference = metalPreference
        self.accessoryStyle = accessoryStyle
        self.preferredStores = preferredStores
        self.age = age
    }
}
