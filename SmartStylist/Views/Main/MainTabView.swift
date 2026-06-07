import SwiftUI

struct MainTabView: View {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .systemThinMaterialDark)
        appearance.shadowColor = UIColor(Color.dsAccentGold.opacity(0.12))

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.dsTextTertiary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Color.dsTextTertiary),
            .font: UIFont.systemFont(ofSize: 10, weight: .regular)
        ]

        UITabBar.appearance().standardAppearance   = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView {
            StyleEngineView()
                .tabItem { Label(Strings.tabsToday, systemImage: "sparkles") }

            VirtualClosetView()
                .tabItem { Label(Strings.tabsWardrobe, systemImage: "tshirt") }

            WardrobeInsightsView()
                .tabItem { Label(Strings.tabsInsights, systemImage: "chart.pie") }

            ProfileSettingsView()
                .tabItem { Label(Strings.tabsProfile, systemImage: "person.crop.circle") }
        }
        .tint(Color.dsAccentGold)
    }
}
