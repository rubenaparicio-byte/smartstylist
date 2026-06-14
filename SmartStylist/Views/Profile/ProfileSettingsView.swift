import SwiftUI
import SwiftData

struct ProfileSettingsView: View {
    @Query private var profiles: [UserProfile]
    @Query private var allItems: [ClothingItem]
    @Query private var outfitHistory: [OutfitHistory]
    @Environment(\.modelContext) private var ctx
    @State private var vm = ProfileViewModel()
    @State private var devTapCount = 0
    @State private var showDevLogs = false
    @State private var showStoreSheet = false
    @State private var showAgeSheet = false
    @State private var ageInput = 25
    @ObservedObject private var logger = DebugLogger.shared
    @AppStorage("preferredLanguage") private var preferredLanguage = "system"

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground.ignoresSafeArea()

                if let profile {
                    ScrollView {
                        VStack(spacing: 14) {
                            identityHero(profile)
                            paletteCard(profile)
                            traitsGrid(profile)
                            styleCard(profile)
                            accountCard(profile)
                            actionSection(profile)
                            if showDevLogs { devLogsSection }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 90) }
                } else {
                    Text(Strings.insightsEmptyTitle)
                        .font(.dsBody)
                        .foregroundStyle(Color.dsTextTertiary)
                }
            }
            .navigationTitle(Strings.profileNavTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(Strings.profileNavTitle)
                        .font(.dsTitle2)
                        .foregroundStyle(Color.dsAccentPrimary)
                        .tracking(3)
                }
            }
            .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
            .alert(Strings.profileRetakeTitle, isPresented: $vm.showRetakeConfirmation) {
                Button(Strings.profileRetakeButton, role: .destructive) {
                    if let p = profile { vm.retakeAnalysis(profile: p, context: ctx) }
                }
                Button(Strings.commonCancel, role: .cancel) { }
            } message: {
                Text(Strings.profileRetakeMessage)
            }
            .alert(Strings.profileDeleteTitle, isPresented: $vm.showDeleteConfirmation) {
                Button(Strings.profileDeleteButton, role: .destructive) {
                    vm.deleteAllData(context: ctx)
                }
                Button(Strings.commonCancel, role: .cancel) { }
            } message: {
                Text(Strings.profileDeleteMessage)
            }
            .sheet(isPresented: $showStoreSheet) {
                if let profile { StoreSelectionView(profile: profile) }
            }
            .sheet(isPresented: $showAgeSheet) {
                agePickerSheet
            }
        }
    }

    // ── Identity Hero ──────────────────────────────────────────────────────────

    private func identityHero(_ profile: UserProfile) -> some View {
        let firstSwatch = profile.recommendedColorSwatches.first
        let accentColor = firstSwatch.map { Color(hex: $0.hex) } ?? Color.dsAccentPrimary

        return ZStack(alignment: .bottomLeading) {
            // Gradient fill
            RoundedRectangle(cornerRadius: DSSize.cornerRadiusCard, style: .continuous)
                .fill(
                    LinearGradient(
                        stops: [
                            .init(color: accentColor.opacity(0.28), location: 0),
                            .init(color: Color.dsCardBackground, location: 0.72)
                        ],
                        startPoint: .topTrailing,
                        endPoint: .bottomLeading
                    )
                )

            // Decorative large circle top-right
            Circle()
                .fill(accentColor.opacity(0.07))
                .frame(width: 180, height: 180)
                .offset(x: 120, y: -60)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .clipShape(RoundedRectangle(cornerRadius: DSSize.cornerRadiusCard, style: .continuous))

            VStack(alignment: .leading, spacing: 0) {
                // Top row — avatar + season
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(accentColor.opacity(0.18))
                            .frame(width: 76, height: 76)
                            .overlay(Circle().stroke(accentColor.opacity(0.35), lineWidth: 1))
                        Image(systemName: "person.fill")
                            .font(.system(size: 30, weight: .thin))
                            .foregroundStyle(accentColor.opacity(0.9))
                    }
                    .onTapGesture {
                        devTapCount += 1
                        if devTapCount >= 5 {
                            showDevLogs.toggle()
                            devTapCount = 0
                        }
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        if profile.seasonalColorimetry.isEmpty {
                            Text("—")
                                .font(.dsTitle)
                                .foregroundStyle(Color.dsTextTertiary)
                        } else {
                            Text(profile.seasonalColorimetry)
                                .font(.dsTitle)
                                .foregroundStyle(Color.dsTextPrimary)
                                .lineLimit(2)
                                .minimumScaleFactor(0.8)
                        }

                        if !profile.metalPreference.isEmpty {
                            let isGold = profile.metalPreference == "Gold"
                            let metalColor = isGold ? Color(hex: "#D4AF37") : Color(hex: "#C0C0C0")
                            HStack(spacing: 5) {
                                Circle().fill(metalColor).frame(width: 7, height: 7)
                                Text(profile.metalPreference)
                                    .font(.dsCaption)
                                    .foregroundStyle(Color.dsTextSecondary)
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 22)
                .padding(.bottom, 18)

                // Stats bar
                HStack(spacing: 0) {
                    heroStat(value: allItems.count, label: Strings.profileStatsItems)
                    statSeparator
                    heroStat(value: outfitHistory.count, label: Strings.profileStatsLooks)
                    statSeparator
                    heroStat(value: profile.preferredStores.count, label: Strings.profileStatsStores)
                }
                .padding(.vertical, 14)
                .background(Color.black.opacity(0.14))
                .clipShape(
                    UnevenRoundedRectangle(
                        bottomLeadingRadius: DSSize.cornerRadiusCard,
                        bottomTrailingRadius: DSSize.cornerRadiusCard
                    )
                )
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: DSSize.cornerRadiusCard, style: .continuous)
                .stroke(accentColor.opacity(0.22), lineWidth: 0.5)
        )
    }

    private func heroStat(value: Int, label: String) -> some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.system(.title2, design: .default, weight: .semibold))
                .foregroundStyle(Color.dsAccentPrimary)
                .contentTransition(.numericText(value: Double(value)))
                .animation(.dsDefault, value: value)
            Text(label)
                .font(.dsCaption)
                .foregroundStyle(Color.dsTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var statSeparator: some View {
        Rectangle()
            .fill(Color.dsAccentPrimary.opacity(0.12))
            .frame(width: 0.5, height: 28)
    }

    // ── Palette Card ───────────────────────────────────────────────────────────

    private func paletteCard(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                cardLabel(Strings.profileSectionDNA)
                Spacer()
                if !profile.seasonalColorimetry.isEmpty {
                    Text(profile.seasonalColorimetry)
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsAccentPrimary.opacity(0.7))
                }
            }

            let recommended = profile.recommendedColorSwatches
            if recommended.isEmpty {
                profileEmptyNote(Strings.profileEmptyColors)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(recommended, id: \.hex) { swatch in
                            paletteSwatch(hex: swatch.hex, name: swatch.name)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }

            let avoid = profile.avoidColorSwatches
            if !avoid.isEmpty {
                HStack(alignment: .center, spacing: 10) {
                    Text(Strings.profileSectionAvoid)
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsTextTertiary.opacity(0.65))
                    Spacer()
                    HStack(spacing: 5) {
                        ForEach(avoid.prefix(6), id: \.hex) { swatch in
                            ZStack {
                                Circle()
                                    .fill(Color(hex: swatch.hex).opacity(0.5))
                                    .frame(width: 22, height: 22)
                                Image(systemName: "xmark")
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundStyle(Color.white.opacity(0.7))
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .luxuryCard()
    }

    private func paletteSwatch(hex: String, name: String) -> some View {
        VStack(spacing: 7) {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 54, height: 54)
                .overlay(Circle().stroke(Color.white.opacity(0.08), lineWidth: 0.5))
                .shadow(color: Color(hex: hex).opacity(0.45), radius: 8, y: 4)
            Text(name)
                .font(.dsCaption)
                .foregroundStyle(Color.dsTextTertiary)
                .multilineTextAlignment(.center)
                .frame(width: 62)
                .lineLimit(2)
        }
    }

    // ── Traits Grid ────────────────────────────────────────────────────────────

    private func traitsGrid(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            cardLabel(Strings.profileSectionPhysical)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                traitCell(icon: "figure.stand",  label: Strings.profileTraitBody, value: localizedBodyType(profile.bodyType))
                traitCell(icon: "drop.fill",     label: Strings.profileTraitSkin, value: profile.skinTone)
                traitCell(icon: "eye",           label: Strings.profileTraitEye,  value: profile.eyeColor)
                traitCell(icon: "wind",          label: Strings.profileTraitHair, value: profile.hairColor)
            }
        }
        .padding(18)
        .luxuryCard()
    }

    private func traitCell(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .ultraLight))
                .foregroundStyle(Color.dsAccentPrimary.opacity(0.65))
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundStyle(Color.dsTextTertiary)
                Text(value.isEmpty ? "—" : value)
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsTextPrimary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 11)
        .background(Color.dsSurface.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: DSSize.cornerRadiusSmall, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DSSize.cornerRadiusSmall, style: .continuous)
                .stroke(Color.dsAccentPrimary.opacity(0.1), lineWidth: 0.5)
        )
    }

    // ── Style + Shopping ───────────────────────────────────────────────────────

    private func styleCard(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            cardLabel(Strings.profileSectionPrefs)

            if profile.accessoryStyle.isEmpty {
                profileEmptyNote(Strings.profileEmptyStyle)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(profile.accessoryStyle, id: \.self) { style in
                        let localized = String(
                            localized: String.LocalizationValue("accessory.\(style.lowercased())"),
                            locale: Strings.activeLocale
                        )
                        Text(localized)
                            .font(.dsCaption)
                            .foregroundStyle(Color.dsAccentPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.dsAccentPrimary.opacity(0.1))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.dsAccentPrimary.opacity(0.3), lineWidth: 0.5))
                    }
                }
            }

            thinRule

            HStack {
                cardLabel(Strings.profileSectionShopping)
                Spacer()
                Button(Strings.profileStoresEdit) { showStoreSheet = true }
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsAccentPrimary.opacity(0.8))
            }

            if profile.preferredStores.isEmpty {
                profileEmptyNote(Strings.profileEmptyStores)
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(profile.preferredStores, id: \.self) { store in
                        Text(store)
                            .font(.dsCaption)
                            .foregroundStyle(Color.dsTextSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.dsSurface.opacity(0.6))
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.dsAccentPrimary.opacity(0.15), lineWidth: 0.5))
                    }
                }
            }
        }
        .padding(18)
        .luxuryCard()
    }

    // ── Account ────────────────────────────────────────────────────────────────

    private func accountCard(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            cardLabel(Strings.profileSectionAccount)
                .padding(.bottom, 14)

            if let gender = profile.gender {
                accountRow(label: Strings.profileTraitGender) {
                    Text(localizedGender(gender))
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsTextPrimary)
                }
                thinRule.padding(.vertical, 0)
            }

            // Age — editable
            Button {
                ageInput = profile.age ?? 25
                showAgeSheet = true
            } label: {
                accountRow(label: Strings.profileTraitAge) {
                    HStack(spacing: 4) {
                        Text(profile.age.map { "\($0)" } ?? "—")
                            .font(.dsCaption)
                            .foregroundStyle(Color.dsTextPrimary)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 9))
                            .foregroundStyle(Color.dsAccentPrimary.opacity(0.4))
                    }
                }
            }

            thinRule.padding(.vertical, 0)

            // Language
            HStack {
                Text(Strings.settingsLanguageLabel)
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsTextTertiary)
                Spacer()
                Picker("", selection: $preferredLanguage) {
                    Text(Strings.settingsLanguageSystem).tag("system")
                    Text(Strings.settingsLanguageEN).tag("en")
                    Text(Strings.settingsLanguageES).tag("es")
                }
                .pickerStyle(.menu)
                .tint(Color.dsAccentPrimary)
            }
            .padding(.vertical, 10)
        }
        .padding(18)
        .luxuryCard()
    }

    private func accountRow<Trailing: View>(label: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack {
            Text(label)
                .font(.dsCaption)
                .foregroundStyle(Color.dsTextTertiary)
            Spacer()
            trailing()
        }
        .padding(.vertical, 10)
    }

    // ── Actions ────────────────────────────────────────────────────────────────

    private func actionSection(_ profile: UserProfile) -> some View {
        VStack(spacing: 10) {
            Button { vm.showRetakeConfirmation = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.counterclockwise")
                    Text(Strings.profileUpdateAnalysis)
                }
                .font(.dsBodyMedium)
                .foregroundStyle(Color.dsAccentPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.dsAccentPrimary, lineWidth: 1)
                )
            }

            Button { vm.showDeleteConfirmation = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text(Strings.profileDeleteButton)
                }
                .font(.dsCaption)
                .foregroundStyle(Color.dsErrorRed.opacity(0.65))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
        }
        .padding(.bottom, 24)
    }

    // ── Age picker sheet ──────────────────────────────────────────────────────

    private var agePickerSheet: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground.ignoresSafeArea()
                VStack(spacing: 24) {
                    Text(Strings.profileTraitAge)
                        .font(.dsLabel)
                        .foregroundStyle(Color.dsTextTertiary)
                        .tracking(2)

                    Picker("", selection: $ageInput) {
                        ForEach(13...99, id: \.self) { age in
                            Text("\(age)").tag(age)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 180)

                    Button {
                        profile?.age = ageInput
                        showAgeSheet = false
                    } label: {
                        Text(Strings.commonSave)
                            .font(.dsBodyMedium)
                            .foregroundStyle(Color.dsBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(Color.dsAccentPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .padding(.horizontal, 24)
                }
            }
            .presentationDetents([.height(340)])
            .presentationDragIndicator(.visible)
        }
    }

    // ── Shared helpers ────────────────────────────────────────────────────────

    private func cardLabel(_ text: String) -> some View {
        Text(text)
            .font(.dsCaption)
            .foregroundStyle(Color.dsTextTertiary)
            .tracking(2)
    }

    private var thinRule: some View {
        Rectangle()
            .fill(Color.dsAccentPrimary.opacity(0.1))
            .frame(height: 0.5)
    }

    private func profileEmptyNote(_ message: String) -> some View {
        Label(message, systemImage: "circle.dashed")
            .font(.dsCaption)
            .foregroundStyle(Color.dsTextTertiary)
    }

    private func localizedGender(_ gender: String) -> String {
        switch gender {
        case "Male":   return Strings.onboardingGenderMale
        case "Female": return Strings.onboardingGenderFemale
        default:       return gender
        }
    }

    private func localizedBodyType(_ rawValue: String) -> String {
        let key = "bodytype.\(rawValue.lowercased().replacingOccurrences(of: " ", with: "_"))"
        let localized = String(localized: String.LocalizationValue(key), locale: Strings.activeLocale)
        return localized == key ? rawValue : localized
    }

    // ── Developer Logs (hidden — 5 taps on avatar) ────────────────────────────

    private var devLogsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DEVELOPER LOGS")
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsTextTertiary)
                    .tracking(2)
                Spacer()
                Button { logger.clear() } label: {
                    Text("Clear")
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsAccentPrimary.opacity(0.7))
                }
            }

            if logger.entries.isEmpty {
                Text("No logs yet.")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(Color.dsTextTertiary)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(logger.entries, id: \.self) { entry in
                            Text(entry)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(Color.dsTextSecondary)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .frame(maxHeight: 320)
            }
        }
        .padding(18)
        .background(Color.black.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.dsAccentPrimary.opacity(0.2), lineWidth: 0.5)
        )
        .padding(.bottom, 16)
    }
}
