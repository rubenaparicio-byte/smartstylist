import SwiftUI
import SwiftData

struct ProfileSettingsView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var ctx
    @State private var vm = ProfileViewModel()
    @State private var devTapCount = 0
    @State private var showDevLogs = false
    @ObservedObject private var logger = DebugLogger.shared
    @AppStorage("preferredLanguage") private var preferredLanguage = "system"

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsDeepSlate.ignoresSafeArea()

                if let profile {
                    ScrollView {
                        VStack(spacing: 20) {
                            profileHeader(profile)
                            colorimetrySection(profile)
                            avoidSection(profile)
                            traitsSection(profile)
                            GoldDivider().padding(.horizontal, 4)
                            languageSection
                            GoldDivider().padding(.horizontal, 4)
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
                        .foregroundStyle(Color.dsAccentGold)
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
        }
    }

    // ── Profile header ────────────────────────────────────────────────────────

    private func profileHeader(_ profile: UserProfile) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.dsSurface)
                    .frame(width: 72, height: 72)
                    .overlay(Circle().stroke(Color.dsAccentGold.opacity(0.35), lineWidth: 0.5))
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 36, weight: .thin))
                    .foregroundStyle(Color.dsAccentGold)
            }
            .onTapGesture {
                devTapCount += 1
                if devTapCount >= 5 {
                    showDevLogs.toggle()
                    devTapCount = 0
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(profile.seasonalColorimetry.isEmpty ? "—" : profile.seasonalColorimetry)
                    .font(.dsTitle2)
                    .foregroundStyle(Color.dsTextPrimary)
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(hex: profile.metalPreference == "Gold" ? "#D4AF37" : "#C0C0C0"))
                        .frame(width: 11, height: 11)
                    Text(profile.metalPreference.isEmpty ? "—" : profile.metalPreference)
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsTextSecondary)
                }
            }
            Spacer()
        }
        .padding(18)
        .luxuryCard()
    }

    // ── Colour palette ────────────────────────────────────────────────────────

    private func colorimetrySection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(Strings.profileSectionColorimetry)
            if profile.recommendedColorHexes.isEmpty {
                emptyNote
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(
                            Array(zip(profile.recommendedColorHexes, profile.recommendedColorNames)),
                            id: \.0
                        ) { hex, name in
                            colorSwatch(hex: hex, name: name)
                        }
                    }
                }
            }
        }
        .padding(18)
        .luxuryCard()
    }

    @ViewBuilder
    private func avoidSection(_ profile: UserProfile) -> some View {
        if !profile.avoidColorHexes.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                sectionHeader(Strings.profileSectionAvoid)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(
                            Array(zip(profile.avoidColorHexes, profile.avoidColorNames)),
                            id: \.0
                        ) { hex, name in
                            colorSwatch(hex: hex, name: name)
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
            .padding(18)
            .luxuryCard()
        }
    }

    // ── Physical traits ───────────────────────────────────────────────────────

    private func traitsSection(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(Strings.profileSectionTraits)
            traitRow(label: Strings.profileTraitBody,  value: profile.bodyType)
            GoldDivider()
            traitRow(label: Strings.profileTraitSkin,  value: profile.skinTone)
            GoldDivider()
            traitRow(label: Strings.profileTraitEye,   value: profile.eyeColor)
            GoldDivider()
            traitRow(label: Strings.profileTraitHair,  value: profile.hairColor)
            GoldDivider()
            traitRow(label: Strings.profileTraitMetal, value: profile.metalPreference)
        }
        .padding(18)
        .luxuryCard()
    }

    // ── Language section ──────────────────────────────────────────────────────

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader(Strings.settingsSectionLanguage)
            HStack {
                Text(Strings.settingsLanguageLabel)
                    .font(.dsBody)
                    .foregroundStyle(Color.dsTextPrimary)
                Spacer()
                Picker("", selection: $preferredLanguage) {
                    Text(Strings.settingsLanguageSystem).tag("system")
                    Text(Strings.settingsLanguageEN).tag("en")
                    Text(Strings.settingsLanguageES).tag("es")
                }
                .pickerStyle(.menu)
                .tint(Color.dsAccentGold)
            }
        }
        .padding(18)
        .luxuryCard()
    }

    // ── Action section ────────────────────────────────────────────────────────

    private func actionSection(_ profile: UserProfile) -> some View {
        VStack(spacing: 20) {
            Button { vm.showRetakeConfirmation = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.counterclockwise")
                    Text(Strings.profileRetakeButton)
                }
                .font(.dsBodyMedium)
                .foregroundStyle(Color.dsAccentGold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.dsAccentGold, lineWidth: 1)
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

    // ── Shared helpers ────────────────────────────────────────────────────────

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.dsCaption)
            .foregroundStyle(Color.dsTextTertiary)
            .tracking(2)
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

    private var emptyNote: some View {
        Text("—")
            .font(.dsCaption)
            .foregroundStyle(Color.dsTextTertiary)
    }

    // ── Developer Logs (hidden — 5 taps on profile icon) ─────────────────────

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
                        .foregroundStyle(Color.dsAccentGold.opacity(0.7))
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
                .stroke(Color.dsAccentGold.opacity(0.2), lineWidth: 0.5)
        )
        .padding(.bottom, 16)
    }
}
