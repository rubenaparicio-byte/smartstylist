import SwiftUI

struct BodyTypeStepView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.onboardingBodyTitle)
                        .editorialStyle()
                    Text(Strings.onboardingBodySubtitle)
                        .font(.dsBody)
                        .foregroundStyle(Color.dsTextSecondary)
                }

                GoldDivider()

                FlowLayout(spacing: 10) {
                    ForEach(vm.bodyTypeOptions, id: \.self) { option in
                        SelectionChip(label: option,
                                      isSelected: vm.selectedBodyType == option) {
                            vm.selectedBodyType = option
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}
