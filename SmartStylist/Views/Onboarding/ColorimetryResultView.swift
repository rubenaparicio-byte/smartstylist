import SwiftUI

struct ColorimetryResultView: View {
    @Bindable var vm: OnboardingViewModel
    let onComplete: () -> Void

    private var analysis: ColorimetryAnalysis? { vm.analysisResult }
    private var season: String { analysis?.season ?? "" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.onboardingResultTitle)
                        .editorialStyle()
                    Text(Strings.onboardingResultSubtitle)
                        .font(.dsBody)
                        .foregroundStyle(Color.dsTextSecondary)
                }

                GoldDivider()

                // ── Season card ───────────────────────────────────────────
                LuxuryCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(season.uppercased())
                                    .font(.dsTitle)
                                    .foregroundStyle(Color.dsAccentGold)
                                    .tracking(3)
                                if let metal = analysis?.metalPreference {
                                    Text(metal.uppercased())
                                        .font(.dsCaption)
                                        .foregroundStyle(Color.dsTextTertiary)
                                        .tracking(1.5)
                                }
                            }
                            Spacer()
                            Image(systemName: seasonIcon(for: season))
                                .foregroundStyle(Color.dsAccentGold)
                                .font(.title2)
                        }

                        if let guidelines = analysis?.guidelines {
                            Text(guidelines)
                                .font(.dsBody)
                                .foregroundStyle(Color.dsTextSecondary)
                        }
                    }
                    .padding(20)
                }

                // ── Recommended palette ───────────────────────────────────
                if let colors = analysis?.recommendedColors, !colors.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(Strings.onboardingResultPalette)
                            .font(.dsLabel)
                            .foregroundStyle(Color.dsTextSecondary)
                            .tracking(2)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(colors, id: \.hex) { swatch in
                                    SwatchCell(swatch: swatch, muted: false)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // ── Colours to minimise ───────────────────────────────────
                if let avoid = analysis?.avoidColors, !avoid.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(Strings.onboardingResultMinimise)
                            .font(.dsLabel)
                            .foregroundStyle(Color.dsTextSecondary)
                            .tracking(2)

                        HStack(spacing: 14) {
                            ForEach(avoid, id: \.hex) { swatch in
                                SwatchCell(swatch: swatch, muted: true)
                            }
                        }
                    }
                }

                // ── Accessory style ───────────────────────────────────────
                VStack(alignment: .leading, spacing: 14) {
                    Text(Strings.onboardingResultAccessoryTitle)
                        .font(.dsLabel)
                        .foregroundStyle(Color.dsTextSecondary)
                        .tracking(2)

                    Text(Strings.onboardingResultAccessorySubtitle)
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsTextTertiary)

                    FlowLayout(spacing: 10) {
                        ForEach(vm.accessoryStyleOptions, id: \.self) { style in
                            let localized = String(
                                localized: String.LocalizationValue("accessory.\(style.lowercased())"),
                                locale: Strings.activeLocale
                            )
                            SelectionChip(
                                label: localized,
                                isSelected: vm.selectedAccessoryStyles.contains(style)
                            ) {
                                if vm.selectedAccessoryStyles.contains(style) {
                                    vm.selectedAccessoryStyles.removeAll { $0 == style }
                                } else {
                                    vm.selectedAccessoryStyles.append(style)
                                }
                            }
                        }
                    }
                }

                Button {
                    // Request notification permission at the end of onboarding, while
                    // the user still has context about daily outfit suggestions.
                    Task { await NotificationService.shared.requestAndSchedule() }
                    onComplete()
                } label: {
                    Text(Strings.onboardingResultEnter)
                        .font(.dsBodyMedium)
                        .foregroundStyle(Color.dsDeepSlate)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.dsAccentGold)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
            .padding(24)
        }
    }

    private func seasonIcon(for season: String) -> String {
        switch season {
        case "Spring":  return "leaf"
        case "Summer":  return "sun.max"
        case "Autumn":  return "wind"
        case "Winter":  return "snowflake"
        default:        return "sparkles"
        }
    }
}

// ── Private swatch cell ───────────────────────────────────────────────────────

private struct SwatchCell: View {
    let swatch: ColorSwatch
    let muted: Bool

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(Color(hex: swatch.hex))
                .frame(width: 46, height: 46)
                .overlay {
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                }
                .opacity(muted ? 0.4 : 1.0)
                .overlay {
                    if muted {
                        Image(systemName: "xmark")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.white.opacity(0.8))
                    }
                }

            Text(swatch.name)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.dsTextTertiary)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 52)
        }
    }
}
