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

extension View {
    func luxuryCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(LuxuryCardStyle(cornerRadius: cornerRadius))
    }
}
