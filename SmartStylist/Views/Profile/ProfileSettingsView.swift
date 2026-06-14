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
                        VStack(spacing: 20) {
                            heroHeader(profile)
                            styleDNASection(profile)
                            physicalSection(profile)
                            preferencesSection(profile)
                            accountSection(profile)
                            actionSection(profile)
                            if showDevLogs {
                                devLogsSection
                            }
                        }
                        .padding(16)
                    }
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

    // ── Hero header ───────────────────────────────────────────────────────────

    private func heroHeader(_ profile: UserProfile) -> some View {
        VStack(spacing: 16) {
            // Avatar + season chip
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.dsSurface)
                        .frame(width: 72, height: 72)
                        .overlay(Circle().stroke(Color.dsAccentPrimary.opacity(0.35), lineWidth: 0.5))
                    Image(systemName: "person.fill")
                        .font(.system(size: 32, weight: .thin))
                        .foregroundStyle(Color.dsAccentPrimary.opacity(0.7))
                }
                .onTapGesture {
                    devTapCount += 1
                    if devTapCount >= 5 {
                        showDevLogs.toggle()
                        devTapCount = 0
                    }
                }

                if !profile.seasonalColorimetry.isEmpty {
                    let metalColor = profile.metalPreference == "Gold"
                        ? Color(hex: "#D4AF37")
                        : Color(hex: "#C0C0C0")
                    HStack(spacing: 5) {
                        Circle()
                            .fill(metalColor)
                            .frame(width: 8, height: 8)
                        Text(profile.metalPreference.isEmpty
                            ? profile.seasonalColorimetry
                            : "\(profile.seasonalColorimetry) · \(profile.metalPreference)")
                            .font(.dsCaption)
                            .foregroundStyle(Color.dsTextSecondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Material.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.dsAccentPrimary.opacity(0.18), lineWidth: 0.5))
                }
            }

            // Stats row
            HStack(spacing: 0) {
                statColumn(value: allItems.count, label: Strings.profileStatsItems)
                Rectangle()
                    .fill(Color.dsAccentPrimary.opacity(0.15))
                    .frame(width: 0.5, height: 32)
                statColumn(value: outfitHistory.count, label: Strings.profileStatsLooks)
                Rectangle()
                    .fill(Color.dsAccentPrimary.opacity(0.15))
                    .frame(width: 0.5, height: 32)
                statColumn(value: profile.preferredStores.count, label: Strings.profileStatsStores)
            }
            .padding(.vertical, 12)
            .background(Color.dsSurface.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: DSSize.cornerRadiusMedium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DSSize.cornerRadiusMedium, style: .continuous)
                    .stroke(Color.dsAccentPrimary.opacity(0.15), lineWidth: 0.5)
            )
        }
        .padding(18)
        .luxuryCard()
    }

    private func statColumn(value: Int, label: String) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(.title2, design: .default, weight: .semibold))
                .foregroundStyle(Color.dsAccentPrimary)
                .contentTransition(.numericText())
            Text(label)
                .font(.dsCaption)
                .foregroundStyle(Color.dsTextTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // ── Style DNA ─────────────────────────────────────────────────────────────

    private func styleDNASection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(Strings.profileSectionDNA)

            if !profile.seasonalColorimetry.isEmpty {
                Text(profile.seasonalColorimetry)
                    .font(.dsBodyMedium)
                    .foregroundStyle(Color.dsTextPrimary)
                AccentDivider()
            }

            // Recommended colours
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.profileSectionColorimetry)
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsTextTertiary)
                let recommended = profile.recommendedColorSwatches
                if recommended.isEmpty {
                    profileEmptyNote(Strings.profileEmptyColors)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(recommended, id: \.hex) { swatch in
                                colorSwatch(hex: swatch.hex, name: swatch.name)
                            }
                        }
                    }
                }
            }

            // Avoid colours (only if non-empty)
            let avoid = profile.avoidColorSwatches
            if !avoid.isEmpty {
                AccentDivider()
                VStack(alignment: .leading, spacing: 8) {
                    Text(Strings.profileSectionAvoid)
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsTextTertiary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(avoid, id: \.hex) { swatch in
                                colorSwatch(hex: swatch.hex, name: swatch.name)
                                    .opacity(0.6)
                                    .overlay(
                                        Image(systemName: "xmark")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundStyle(Color.white.opacity(0.8))
                                    )
                            }
                        }
                    }
                }
            }
        }
        .padding(18)
        .luxuryCard()
    }

    // ── Physical profile ──────────────────────────────────────────────────────

    private func physicalSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(Strings.profileSectionPhysical)
            traitRow(label: Strings.profileTraitBody, value: localizedBodyType(profile.bodyType))
            AccentDivider()
            traitRow(label: Strings.profileTraitSkin, value: profile.skinTone)
            AccentDivider()
            traitRow(label: Strings.profileTraitEye,  value: profile.eyeColor)
            AccentDivider()
            traitRow(label: Strings.profileTraitHair, value: profile.hairColor)
        }
        .padding(18)
        .luxuryCard()
    }

    // ── Preferences ───────────────────────────────────────────────────────────

    private func preferencesSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(Strings.profileSectionPrefs)

            // Accessory style chips
            VStack(alignment: .leading, spacing: 8) {
                Text(Strings.profileTraitAccessoryStyle)
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsTextTertiary)
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
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.dsAccentPrimary.opacity(0.12))
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.dsAccentPrimary.opacity(0.35), lineWidth: 0.5))
                        }
                    }
                }
            }

            AccentDivider()

            // Preferred stores
            HStack {
                Text(Strings.profileSectionShopping)
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsTextTertiary)
                Spacer()
                Button(Strings.profileStoresEdit) {
                    showStoreSheet = true
                }
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
                            .overlay(Capsule().stroke(Color.dsAccentPrimary.opacity(0.2), lineWidth: 0.5))
                    }
                }
            }
        }
        .padding(18)
        .luxuryCard()
    }

    // ── Account ───────────────────────────────────────────────────────────────

    private func accountSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(Strings.profileSectionAccount)

            if let gender = profile.gender {
                traitRow(label: Strings.profileTraitGender, value: localizedGender(gender))
                AccentDivider()
            }

            // Age (editable)
            HStack {
                Text(Strings.profileTraitAge)
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsTextTertiary)
                Spacer()
                Button {
                    ageInput = profile.age ?? 25
                    showAgeSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Text(profile.age.map { "\($0)" } ?? "—")
                            .font(.dsBodyMedium)
                            .foregroundStyle(Color.dsTextPrimary)
                        Image(systemName: "pencil")
                            .font(.caption)
                            .foregroundStyle(Color.dsAccentPrimary.opacity(0.7))
                    }
                }
            }

            AccentDivider()

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
        }
        .padding(18)
        .luxuryCard()
    }

    // ── Actions ───────────────────────────────────────────────────────────────

    private func actionSection(_ profile: UserProfile) -> some View {
        VStack(spacing: 16) {
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

            VStack(alignment: .leading, spacing: 12) {
                Text(Strings.profileDangerZone)
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsErrorRed.opacity(0.8))
                    .tracking(2)

                Button { vm.showDeleteConfirmation = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "trash")
                        Text(Strings.profileDeleteButton)
                    }
                    .font(.dsBodyMedium)
                    .foregroundStyle(Color.dsErrorRed)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(Color.dsErrorRed.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.dsErrorRed.opacity(0.45), lineWidth: 0.5)
                    )
                }
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

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.dsCaption)
            .foregroundStyle(Color.dsTextTertiary)
            .tracking(2)
    }

    private func profileEmptyNote(_ message: String) -> some View {
        Label(message, systemImage: "circle.dashed")
            .font(.dsCaption)
            .foregroundStyle(Color.dsTextTertiary)
    }

    private func colorSwatch(hex: String, name: String) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(Color(hex: hex))
                .frame(width: 46, height: 46)
                .overlay(Circle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                .shadow(color: Color(hex: hex).opacity(0.35), radius: 6, y: 3)
            Text(name)
                .font(.dsCaption)
                .foregroundStyle(Color.dsTextTertiary)
                .multilineTextAlignment(.center)
                .frame(width: 58)
                .lineLimit(2)
        }
    }

    private func traitRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.dsCaption)
                .foregroundStyle(Color.dsTextTertiary)
            Spacer()
            Text(value.isEmpty ? "—" : value)
                .font(.dsBodyMedium)
                .foregroundStyle(Color.dsTextPrimary)
        }
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
                Button {
                    logger.clear()
                } label: {
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
