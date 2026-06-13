import SwiftUI

struct LanguageStepView: View {
    @Bindable var vm: OnboardingViewModel
    @AppStorage("preferredLanguage") private var preferredLanguage = "system"

    private let options: [(value: String, flag: String, label: String, sublabel: String)] = [
        ("system", "🌐", "System",  "Follows device language"),
        ("en",     "🇬🇧", "English", "English"),
        ("es",     "🇪🇸", "Español", "Castellano")
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("WELCOME\nTO SMARTSTYLIST")
                        .editorialStyle()
                    Text("Choose your language to personalise your experience.")
                        .font(.dsBody)
                        .foregroundStyle(Color.dsTextSecondary)
                }

                GoldDivider()

                VStack(spacing: 14) {
                    ForEach(options, id: \.value) { opt in
                        languageCard(opt)
                    }
                }
            }
            .padding(24)
        }
    }

    private func languageCard(_ opt: (value: String, flag: String, label: String, sublabel: String)) -> some View {
        let selected = preferredLanguage == opt.value
        return Button {
            preferredLanguage = opt.value
            vm.selectedLanguage = opt.value
        } label: {
            HStack(spacing: 18) {
                Text(opt.flag)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 3) {
                    Text(opt.label)
                        .font(.dsBodyMedium)
                        .foregroundStyle(selected ? Color.dsAccentGold : Color.dsTextPrimary)
                    Text(opt.sublabel)
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsTextTertiary)
                }

                Spacer()

                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.dsAccentGold)
                        .font(.title3)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(18)
            .background(selected ? Color.dsAccentGold.opacity(0.08) : Color.dsSurface.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        selected ? Color.dsAccentGold.opacity(0.6) : Color.dsAccentGold.opacity(0.12),
                        lineWidth: selected ? 1.5 : 0.5
                    )
            }
        }
        .accessibilityIdentifier("language.\(opt.value)")
        .animation(.dsDefault, value: selected)
    }
}
