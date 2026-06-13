import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(AuthService.self) private var auth
    @Query private var profiles: [UserProfile]

    // Bypass auth and use a clean onboarding flow when launched by UI tests.
    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    private var isOnboarded: Bool {
        profiles.first?.onboardingCompleted == true
    }

    var body: some View {
        Group {
            if isUITesting {
                OnboardingContainerView()
            } else if !auth.isAuthenticated {
                LoginView()
            } else if isOnboarded {
                MainTabView()
            } else {
                OnboardingContainerView()
            }
        }
        // Verify Apple credential validity on every cold launch — skipped in UI tests.
        .task {
            guard !isUITesting else { return }
            await auth.validateAppleCredential()
        }
    }
}
