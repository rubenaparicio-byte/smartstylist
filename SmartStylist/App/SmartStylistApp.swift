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
        .modelContainer(Self.modelContainer)
    }

    // Static container so App.init() (which resets @State) never recreates the store.
    // UI tests pass --uitesting to get a fresh in-memory store with no CloudKit.
    private static let modelContainer: ModelContainer = {
        let schema = Schema([UserProfile.self, ClothingItem.self, OutfitHistory.self, PlannedLook.self])
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")
        let config: ModelConfiguration
        if isUITesting {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            config = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
        }
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Could not set up ModelContainer: \(error)")
        }
    }()
}
