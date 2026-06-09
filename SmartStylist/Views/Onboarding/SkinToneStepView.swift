import SwiftUI

struct SkinToneStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.onboardingSkinTitle)
                        .editorialStyle()
                    Text(Strings.onboardingSkinSubtitle)
                        .font(.dsBody)
                        .foregroundStyle(Color.dsTextSecondary)
                }
                GoldDivider()
                FlowLayout(spacing: 10) {
                    ForEach(vm.skinToneOptions, id: \.self) { option in
                        SelectionChip(
                            label: option,
                            isSelected: vm.selectedSkinTone == option,
                            swatchColor: skinToneColor(for: option)
                        ) {
                            vm.selectedSkinTone = option
                        }
                    }
                }
            }
            .padding(24)
        }
    }

    private func skinToneColor(for tone: String) -> Color {
        switch tone {
        case "Warm Light":   return Color(hex: "#F2D8C2")
        case "Warm Medium":  return Color(hex: "#C8956C")
        case "Warm Deep":    return Color(hex: "#7D4B2A")
        case "Cool Light":   return Color(hex: "#F5D5D0")
        case "Cool Medium":  return Color(hex: "#C47D7D")
        case "Cool Deep":    return Color(hex: "#6B3545")
        case "Neutral":      return Color(hex: "#D4B896")
        default:             return Color.dsSurface
        }
    }
}
