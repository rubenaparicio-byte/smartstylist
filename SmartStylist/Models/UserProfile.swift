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

    init(id: UUID = UUID(),
         bodyType: String = "",
         skinTone: String = "",
         eyeColor: String = "",
         hairColor: String = "",
         seasonalColorimetry: String = "",
         styleGuidelines: String = "",
         onboardingCompleted: Bool = false) {
        self.id = id
        self.bodyType = bodyType
        self.skinTone = skinTone
        self.eyeColor = eyeColor
        self.hairColor = hairColor
        self.seasonalColorimetry = seasonalColorimetry
        self.styleGuidelines = styleGuidelines
        self.onboardingCompleted = onboardingCompleted
    }
}
