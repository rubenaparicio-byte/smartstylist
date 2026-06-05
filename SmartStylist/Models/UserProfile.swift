import Foundation
import SwiftData

@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var bodyType: String
    var skinTone: String
    var eyeColor: String
    var hairColor: String
    var seasonalColorimetry: String
    var styleGuidelines: String
    var onboardingCompleted: Bool
    var recommendedColorNames: [String]
    var recommendedColorHexes: [String]
    var avoidColorNames: [String]
    var avoidColorHexes: [String]
    var metalPreference: String

    init(id: UUID = UUID(),
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
         metalPreference: String = "Gold") {
        self.id = id
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
    }
}
