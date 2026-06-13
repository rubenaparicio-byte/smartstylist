import SwiftUI

struct AccentDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.dsAccentPrimary.opacity(0.25))
            .frame(height: 0.5)
            .accessibilityHidden(true)
    }
}
