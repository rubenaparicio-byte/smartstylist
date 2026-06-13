import SwiftUI

struct GoldDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.dsAccentGold.opacity(0.25))
            .frame(height: 0.5)
            .accessibilityHidden(true)
    }
}
