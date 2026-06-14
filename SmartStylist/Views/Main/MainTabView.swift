import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                StyleEngineRootView()
                    .tag(0)
                    .toolbar(.hidden, for: .tabBar)

                VirtualClosetView()
                    .tag(1)
                    .toolbar(.hidden, for: .tabBar)

                WardrobeInsightsView()
                    .tag(2)
                    .toolbar(.hidden, for: .tabBar)

                ProfileSettingsView()
                    .tag(3)
                    .toolbar(.hidden, for: .tabBar)
            }
            .tint(Color.dsAccentPrimary)
            .task { await NotificationService.shared.scheduleDailyLookNotification() }

            FloatingTabBarView(selectedTab: $selectedTab)
                .padding(.bottom, 8)
        }
    }
}
