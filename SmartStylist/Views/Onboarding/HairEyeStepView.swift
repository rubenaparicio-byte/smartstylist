import SwiftUI

struct HairEyeStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.onboardingHairTitle)
                        .editorialStyle()
                    Text(Strings.onboardingHairSubtitle)
                        .font(.dsBody)
                        .foregroundStyle(Color.dsTextSecondary)
                }
                GoldDivider()

                VStack(alignment: .leading, spacing: 20) {
                    Text(Strings.onboardingHairColour).font(.dsLabel).foregroundStyle(Color.dsTextSecondary)
                    FlowLayout(spacing: 10) {
                        ForEach(vm.hairColorOptions, id: \.self) { option in
                            SelectionChip(label: option,
                                          isSelected: vm.selectedHairColor == option) {
                                vm.selectedHairColor = option
                            }
                        }
                    }

                    Text(Strings.onboardingEyeColour).font(.dsLabel).foregroundStyle(Color.dsTextSecondary)
                    FlowLayout(spacing: 10) {
                        ForEach(vm.eyeColorOptions, id: \.self) { option in
                            SelectionChip(label: option,
                                          isSelected: vm.selectedEyeColor == option) {
                                vm.selectedEyeColor = option
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}
