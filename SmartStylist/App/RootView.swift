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
