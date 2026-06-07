import SwiftUI
import SwiftData

@main
struct SmartStylistApp: App {
    @State private var auth = AuthService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
        }
        .modelContainer(for: [UserProfile.self, ClothingItem.self, OutfitHistory.self])
    }
}
