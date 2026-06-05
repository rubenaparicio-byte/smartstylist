import SwiftUI

struct SelectionChip: View {
    let label: String
    let isSelected: Bool
    var swatchColor: Color? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let color = swatchColor {
                    Circle()
                        .fill(color)
                        .frame(width: 14, height: 14)
                        .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                }
                Text(label)
                    .font(.dsLabel)
                    .foregroundStyle(isSelected ? Color.dsDeepSlate : Color.dsTextSecondary)
            }
            .padding(.horizontal, swatchColor != nil ? 14 : 18)
            .padding(.vertical, 10)
            .background(isSelected ? Color.dsAccentGold : Color.dsSurface)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.dsAccentGold.opacity(isSelected ? 0 : 0.3), lineWidth: 0.5)
            )
        }
        .animation(.dsDefault, value: isSelected)
    }
}
