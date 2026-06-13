import SwiftUI

struct GenderStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.onboardingGenderTitle)
                        .editorialStyle()
                    Text(Strings.onboardingGenderSubtitle)
                        .font(.dsBody)
                        .foregroundStyle(Color.dsTextSecondary)
                }

                AccentDivider()

                HStack(spacing: 16) {
                    genderCard("Male",   icon: "figure.stand",       label: Strings.onboardingGenderMale)
                    genderCard("Female", icon: "figure.stand.dress",  label: Strings.onboardingGenderFemale)
                }
            }
            .padding(24)
        }
    }

    private func genderCard(_ value: String, icon: String, label: String) -> some View {
        let selected = vm.selectedGender == value
        return Button {
            vm.selectedGender = value
            if vm.selectedBodyType.isNotEmpty {
                vm.selectedBodyType = ""
            }
        } label: {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(selected ? Color.dsAccentPrimary : Color.dsSurface)
                        .frame(width: 80, height: 80)
                    Image(systemName: icon)
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(selected ? Color.dsBackground : Color.dsTextSecondary)
                }
                .shadow(color: selected ? Color.dsAccentPrimary.opacity(0.35) : .clear, radius: 12, y: 6)

                Text(label)
                    .font(.dsBodyMedium)
                    .foregroundStyle(selected ? Color.dsAccentPrimary : Color.dsTextPrimary)
                    .tracking(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .background(selected ? Color.dsAccentPrimary.opacity(0.08) : Color.dsSurface.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        selected ? Color.dsAccentPrimary.opacity(0.6) : Color.dsAccentPrimary.opacity(0.12),
                        lineWidth: selected ? 1.5 : 0.5
                    )
            }
        }
        .accessibilityIdentifier("gender.\(value.lowercased())")
        .animation(.dsSpring, value: selected)
    }
}

private extension String {
    var isNotEmpty: Bool { !isEmpty }
}
