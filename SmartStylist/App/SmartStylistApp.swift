import SwiftUI
import SwiftData

@main
struct SmartStylistApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [UserProfile.self, ClothingItem.self, OutfitHistory.self])
    }
}
