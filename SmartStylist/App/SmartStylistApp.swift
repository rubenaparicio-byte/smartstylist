import SwiftUI
import SwiftData

@main
struct SmartStylistApp: App {
    @State private var auth = AuthService()
    @AppStorage("preferredLanguage") private var preferredLanguage = "system"

    private var activeLocale: Locale {
        switch preferredLanguage {
        case "es": return Locale(identifier: "es")
        case "en": return Locale(identifier: "en")
        default:   return .autoupdatingCurrent
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
                .environment(\.locale, activeLocale)
        }
        .modelContainer(for: [UserProfile.self, ClothingItem.self, OutfitHistory.self])
    }
}
