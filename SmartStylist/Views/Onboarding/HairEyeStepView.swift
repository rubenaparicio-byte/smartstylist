import SwiftUI

struct HairEyeStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("HAIR &\nEYES")
                        .editorialStyle()
                    Text("These details complete your chromatic profile.")
                        .font(.dsBody)
                        .foregroundStyle(Color.dsTextSecondary)
                }
                GoldDivider()

                VStack(alignment: .leading, spacing: 20) {
                    Text("Hair Colour").font(.dsLabel).foregroundStyle(Color.dsTextSecondary)
                    FlowLayout(spacing: 10) {
                        ForEach(vm.hairColorOptions, id: \.self) { option in
                            SelectionChip(label: option,
                                          isSelected: vm.selectedHairColor == option) {
                                vm.selectedHairColor = option
                            }
                        }
                    }

                    Text("Eye Colour").font(.dsLabel).foregroundStyle(Color.dsTextSecondary)
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
