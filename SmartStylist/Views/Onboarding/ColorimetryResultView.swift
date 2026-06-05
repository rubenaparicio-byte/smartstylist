import SwiftUI

struct ColorimetryResultView: View {
    let vm: OnboardingViewModel
    let onComplete: () -> Void

    private var season: String { vm.analysisResult?.season ?? "" }
    private var guidelines: String { vm.analysisResult?.guidelines ?? "" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("YOUR\nSEASON")
                        .editorialStyle()
                    Text("Your chromatic identity has been analysed.")
                        .font(.dsBody)
                        .foregroundStyle(Color.dsTextSecondary)
                }

                GoldDivider()

                LuxuryCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(season.uppercased())
                                .font(.dsTitle)
                                .foregroundStyle(Color.dsAccentGold)
                                .tracking(3)
                            Spacer()
                            Image(systemName: seasonIcon(for: season))
                                .foregroundStyle(Color.dsAccentGold)
                                .font(.title2)
                        }
                        Text(guidelines)
                            .font(.dsBody)
                            .foregroundStyle(Color.dsTextSecondary)
                    }
                    .padding(20)
                }

                Button(action: onComplete) {
                    Text("Enter My Wardrobe")
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
