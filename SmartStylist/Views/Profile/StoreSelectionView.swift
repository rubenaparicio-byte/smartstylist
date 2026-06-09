import SwiftUI
import SwiftData

struct StoreSelectionView: View {
    let profile: UserProfile
    @Environment(\.dismiss) private var dismiss

    private let sections: [(title: String, key: String, stores: [String])] = [
        ("Budget",    "stores.section.budget",   ["Zara", "H&M", "Primark", "Shein", "C&A", "Bershka"]),
        ("Mid-range", "stores.section.mid",      ["Mango", "Pull&Bear", "Stradivarius", "Reserved", "Uniqlo", "Springfield", "ASOS"]),
        ("Premium",   "stores.section.premium",  ["COS", "Massimo Dutti", "& Other Stories", "Arket", "Adolfo Domínguez"]),
        ("Sports",    "stores.section.sports",   ["Nike", "Adidas", "New Balance", "Under Armour", "Levi's"])
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsDeepSlate.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        Text(Strings.storesSubtitle)
                            .font(.dsBody)
                            .foregroundStyle(Color.dsTextSecondary)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        ForEach(sections, id: \.key) { section in
                            storeSection(section)
                        }

                        Spacer(minLength: 32)
                    }
                }
            }
            .navigationTitle(Strings.storesNavTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(Strings.storesNavTitle)
                        .font(.dsTitle2)
                        .foregroundStyle(Color.dsAccentGold)
                        .tracking(3)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.storesDone) { dismiss() }
                        .foregroundStyle(Color.dsAccentGold)
                        .font(.dsBodyMedium)
                }
            }
            .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
        }
    }

    private func storeSection(_ section: (title: String, key: String, stores: [String])) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(String(localized: String.LocalizationValue(section.key), locale: Strings.activeLocale))
                .font(.dsCaption)
                .foregroundStyle(Color.dsTextTertiary)
                .tracking(2)
                .padding(.horizontal, 20)

            FlowLayout(spacing: 10) {
                ForEach(section.stores, id: \.self) { store in
                    storeChip(store)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func storeChip(_ store: String) -> some View {
        let selected = profile.preferredStores.contains(store)
        return Button {
            if selected {
                profile.preferredStores.removeAll { $0 == store }
            } else {
                profile.preferredStores.append(store)
            }
        } label: {
            HStack(spacing: 6) {
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color.dsDeepSlate)
                }
                Text(store)
                    .font(.dsBodyMedium)
                    .foregroundStyle(selected ? Color.dsDeepSlate : Color.dsTextPrimary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selected ? Color.dsAccentGold : Color.dsSurface.opacity(0.6))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(selected ? Color.dsAccentGold : Color.dsAccentGold.opacity(0.2), lineWidth: 0.5)
            }
        }
        .animation(.dsDefault, value: selected)
    }
}
