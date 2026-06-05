import SwiftUI

struct SkinToneStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("SKIN\nTONE")
                        .editorialStyle()
                    Text("Your skin's undertone shapes your entire colour palette.")
                        .font(.dsBody)
                        .foregroundStyle(Color.dsTextSecondary)
                }
                GoldDivider()
                FlowLayout(spacing: 10) {
                    ForEach(vm.skinToneOptions, id: \.self) { option in
                        SelectionChip(label: option,
                                      isSelected: vm.selectedSkinTone == option) {
                            vm.selectedSkinTone = option
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}
