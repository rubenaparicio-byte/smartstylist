import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [UserProfile]

    private var isOnboarded: Bool {
        profiles.first?.onboardingCompleted == true
    }

    var body: some View {
        if isOnboarded {
            MainTabView()
        } else {
            OnboardingContainerView()
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            StyleEngineView()
                .tabItem { Label("Today", systemImage: "sparkles") }

            VirtualClosetView()
                .tabItem { Label("Wardrobe", systemImage: "tshirt") }
        }
        .tint(Color.dsAccentGold)
        .background(Color.dsDeepSlate)
    }
}
