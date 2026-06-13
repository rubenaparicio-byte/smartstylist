import SwiftUI

struct FloatingTabBarView: View {
    @Binding var selectedTab: Int

    private struct TabItem {
        let icon: String
        let label: String
    }

    private let tabs: [TabItem] = [
        TabItem(icon: "sparkles",          label: Strings.tabsToday),
        TabItem(icon: "tshirt",            label: Strings.tabsWardrobe),
        TabItem(icon: "chart.pie",         label: Strings.tabsInsights),
        TabItem(icon: "person.crop.circle", label: Strings.tabsProfile)
    ]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                Button {
                    guard selectedTab != index else { return }
                    HapticManager.impact(.light)
                    withAnimation(.dsSpring) { selectedTab = index }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tabs[index].icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(
                                selectedTab == index
                                    ? Color.dsAccentPrimary
                                    : Color.dsTextTertiary
                            )
                            .scaleEffect(selectedTab == index ? 1.15 : 1.0)

                        Circle()
                            .fill(Color.dsAccentPrimary)
                            .frame(width: 4, height: 4)
                            .opacity(selectedTab == index ? 1.0 : 0.0)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .animation(.dsSpring, value: selectedTab)
                }
                .accessibilityLabel(tabs[index].label)
                .accessibilityAddTraits(selectedTab == index ? .isSelected : [])
            }
        }
        .padding(.horizontal, 8)
        .glassCard(cornerRadius: 32)
        .shadow(color: Color.dsGlow, radius: 20, x: 0, y: 8)
        .padding(.horizontal, 24)
    }
}
