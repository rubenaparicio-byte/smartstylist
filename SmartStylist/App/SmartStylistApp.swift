import GoogleSignIn
import SwiftData
import SwiftUI

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
                .onOpenURL { GIDSignIn.sharedInstance.handle($0) }
        }
        .modelContainer(for: [UserProfile.self, ClothingItem.self, OutfitHistory.self])
    }
}
