import SwiftUI

struct SelectionChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.dsLabel)
                .foregroundStyle(isSelected ? Color.dsDeepSlate : Color.dsTextSecondary)
                .padding(.horizontal, 18)
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
