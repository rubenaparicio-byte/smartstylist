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
                AccentDivider()

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    ForEach(vm.skinToneOptions, id: \.self) { tone in
                        SkinToneCard(
                            tone: tone,
                            isSelected: vm.selectedSkinTone == tone
                        ) {
                            vm.selectedSkinTone = tone
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}

// ── Skin tone card ────────────────────────────────────────────────────────────

private struct SkinToneCard: View {
    let tone: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Circle()
                    .fill(gradient)
                    .frame(width: 64, height: 64)
                    .overlay {
                        Circle()
                            .stroke(isSelected ? Color.dsAccentPrimary : Color.white.opacity(0.12), lineWidth: isSelected ? 2 : 0.5)
                    }
                    .shadow(color: baseColor.opacity(0.4), radius: 10, y: 5)

                Text(localizedName)
                    .font(.dsBodyMedium)
                    .foregroundStyle(isSelected ? Color.dsAccentPrimary : Color.dsTextPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(description)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(Color.dsTextTertiary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.dsAccentPrimary.opacity(0.08) : Color.dsSurface.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isSelected ? Color.dsAccentPrimary.opacity(0.6) : Color.dsAccentPrimary.opacity(0.12),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            }
        }
        .animation(.dsDefault, value: isSelected)
    }

    private var baseColor: Color {
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

    private var gradient: RadialGradient {
        RadialGradient(
            colors: [baseColor.opacity(0.7), baseColor],
            center: .topLeading,
            startRadius: 5,
            endRadius: 38
        )
    }

    private var localizedName: String {
        String(localized: String.LocalizationValue("skintone.\(tone.lowercased().replacingOccurrences(of: " ", with: "_"))"),
               locale: Strings.activeLocale)
    }

    private var description: String {
        String(localized: String.LocalizationValue("skintone.\(tone.lowercased().replacingOccurrences(of: " ", with: "_")).desc"),
               locale: Strings.activeLocale)
    }
}
