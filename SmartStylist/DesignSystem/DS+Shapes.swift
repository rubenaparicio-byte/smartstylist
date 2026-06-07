import SwiftUI

struct ContinuousCard: Shape {
    var radius: CGFloat = 20
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(roundedRect: rect,
                          byRoundingCorners: .allCorners,
                          cornerRadii: CGSize(width: radius, height: radius)).cgPath)
    }
}

struct LuxuryCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(Color.dsCardSlate)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.dsAccentGold.opacity(0.15), lineWidth: 0.5)
            )
    }
}

struct GlassCardStyle: ViewModifier {
    var cornerRadius: CGFloat = 20

    func body(content: Content) -> some View {
        content
            .background(Material.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.dsAccentGold.opacity(0.18), lineWidth: 0.5)
            )
    }
}

struct CardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.dsSnappy, value: configuration.isPressed)
    }
}

extension View {
    func luxuryCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(LuxuryCardStyle(cornerRadius: cornerRadius))
    }

    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCardStyle(cornerRadius: cornerRadius))
    }
}
