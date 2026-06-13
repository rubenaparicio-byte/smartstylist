import SwiftUI

struct BodyTypeStepView: View {
    @Bindable var vm: OnboardingViewModel

    private struct BodyOption: Identifiable {
        var id: String { rawValue }
        let rawValue: String
        let icon: String
        let titleKey: String
        let descKey: String
    }

    private let femaleOptions: [BodyOption] = [
        BodyOption(rawValue: "Hourglass",         icon: "diamond",             titleKey: "bodytype.hourglass",        descKey: "bodytype.hourglass.desc"),
        BodyOption(rawValue: "Rectangle",         icon: "rectangle.portrait",  titleKey: "bodytype.rectangle",        descKey: "bodytype.rectangle.desc"),
        BodyOption(rawValue: "Triangle",          icon: "triangle.fill",       titleKey: "bodytype.triangle",         descKey: "bodytype.triangle.desc"),
        BodyOption(rawValue: "Inverted Triangle", icon: "triangle",            titleKey: "bodytype.inverted_triangle",descKey: "bodytype.inverted_triangle.desc"),
        BodyOption(rawValue: "Oval",              icon: "oval.portrait",       titleKey: "bodytype.oval",             descKey: "bodytype.oval.desc")
    ]

    private let maleOptions: [BodyOption] = [
        BodyOption(rawValue: "Athletic",   icon: "figure.strengthtraining.traditional", titleKey: "bodytype.athletic",   descKey: "bodytype.athletic.desc"),
        BodyOption(rawValue: "Rectangle",  icon: "rectangle.portrait",                  titleKey: "bodytype.rectangle",  descKey: "bodytype.rectangle.desc"),
        BodyOption(rawValue: "Oval",       icon: "oval.portrait",                       titleKey: "bodytype.oval",       descKey: "bodytype.oval.desc"),
        BodyOption(rawValue: "Trapezoid",  icon: "trapezoid.and.line.horizontal",       titleKey: "bodytype.trapezoid",  descKey: "bodytype.trapezoid.desc"),
        BodyOption(rawValue: "Triangle",   icon: "triangle.fill",                       titleKey: "bodytype.triangle",   descKey: "bodytype.triangle.desc")
    ]

    private var options: [BodyOption] {
        vm.selectedGender == "Male" ? maleOptions : femaleOptions
    }

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

                AccentDivider()

                VStack(spacing: 12) {
                    ForEach(options) { option in
                        bodyCard(option)
                    }
                }
            }
            .padding(24)
        }
    }

    private func bodyCard(_ option: BodyOption) -> some View {
        let selected = vm.selectedBodyType == option.rawValue
        return Button {
            vm.selectedBodyType = option.rawValue
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(selected ? Color.dsAccentPrimary : Color.dsSurface)
                        .frame(width: 48, height: 48)
                    Image(systemName: option.icon)
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(selected ? Color.dsBackground : Color.dsTextSecondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: String.LocalizationValue(option.titleKey), locale: Strings.activeLocale))
                        .font(.dsBodyMedium)
                        .foregroundStyle(selected ? Color.dsAccentPrimary : Color.dsTextPrimary)
                    Text(String(localized: String.LocalizationValue(option.descKey), locale: Strings.activeLocale))
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsTextTertiary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                if selected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.dsAccentPrimary)
                        .font(.body.weight(.semibold))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(16)
            .background(selected ? Color.dsAccentPrimary.opacity(0.08) : Color.dsSurface.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        selected ? Color.dsAccentPrimary.opacity(0.6) : Color.dsAccentPrimary.opacity(0.12),
                        lineWidth: selected ? 1.5 : 0.5
                    )
            }
        }
        .animation(.dsDefault, value: selected)
    }
}
