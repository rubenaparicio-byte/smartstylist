import Foundation
import SwiftData
import Observation

// ── ProfileViewModel ──────────────────────────────────────────────────────────
// Manages profile display state and data-mutation operations (retake / delete).
// @MainActor because ModelContext mutations must run on the main thread.

@MainActor
@Observable
final class ProfileViewModel {
    var showRetakeConfirmation = false
    var showDeleteConfirmation = false

    /// Deletes the profile so RootView's @Query sees it as nil → shows Onboarding.
    /// The wardrobe (ClothingItem) is intentionally preserved.
    func retakeAnalysis(profile: UserProfile, context: ModelContext) {
        context.delete(profile)
        try? context.save()
    }

    /// Purges every SwiftData entity — fulfils Apple's data-deletion requirement.
    func deleteAllData(context: ModelContext) {
        try? context.delete(model: UserProfile.self)
        try? context.delete(model: ClothingItem.self)
        try? context.delete(model: OutfitHistory.self)
        try? context.save()
    }
}
