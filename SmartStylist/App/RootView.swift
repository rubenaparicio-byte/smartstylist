import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AuthService.self) private var auth
    @Query private var profiles: [UserProfile]

    private var isOnboarded: Bool {
        profiles.first?.onboardingCompleted == true
    }

    var body: some View {
        Group {
            if !auth.isAuthenticated {
                LoginView()
            } else if isOnboarded {
                MainTabView()
            } else {
                OnboardingContainerView()
            }
        }
        // Verify Apple credential validity on every cold launch.
        .task { await auth.validateAppleCredential() }
    }
}
