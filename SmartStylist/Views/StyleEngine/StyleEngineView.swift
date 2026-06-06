import SwiftUI
import SwiftData

struct StyleEngineView: View {
    @Query private var allItems: [ClothingItem]
    @Query private var history: [OutfitHistory]
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var ctx
    @State private var vm = StyleEngineViewModel()

    private var activeItems: [ClothingItem] { allItems.filter { $0.status == .active } }
    private var profile: UserProfile? { profiles.first(where: { $0.onboardingCompleted }) }

    // Maps ViewModel state to a single Equatable key for SwiftUI transitions.
    private enum DisplayState: Equatable {
        case loading, error, suggestion, empty
    }

    private var displayState: DisplayState {
        if vm.isLoading         { return .loading }
        if vm.currentError != nil { return .error }
        if vm.suggestion != nil  { return .suggestion }
        return .empty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsDeepSlate.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if let wx = vm.currentWeather {
                            WeatherBadgeView(weather: wx)
                        }
                        eventContextPicker
                        contentSection
                    }
                    .padding(16)
                    .padding(.bottom, 32)
                    .animation(.dsDefault, value: displayState)
                }
            }
            .navigationTitle("Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(Strings.styleNavTitle)
                        .font(.dsTitle2)
                        .foregroundStyle(Color.dsAccentGold)
                        .tracking(3)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            guard let p = profile else { return }
                            await vm.generateOutfit(profile: p,
                                                    activeItems: activeItems,
                                                    history: history)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.dsAccentGold)
                            .rotationEffect(.degrees(vm.isLoading ? 360 : 0))
                            .animation(
                                vm.isLoading
                                    ? .linear(duration: 1).repeatForever(autoreverses: false)
                                    : .default,
                                value: vm.isLoading
                            )
                    }
                    .disabled(vm.isLoading)
                }
            }
            .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
            .task {
                guard let p = profile, vm.suggestion == nil, !vm.isLoading else { return }
                await vm.generateOutfit(profile: p, activeItems: activeItems, history: history)
            }
        }
    }

    // ── Event context picker ──────────────────────────────────────────────────

    private var eventContextPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Strings.styleEventContext)
                .font(.dsLabel)
                .foregroundStyle(Color.dsTextSecondary)
                .tracking(2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EventContext.allCases, id: \.self) { context in
                        Button {
                            vm.occasion = context
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: context.icon).font(.caption)
                                Text(context.localizedName).font(.dsLabel)
                            }
                            .foregroundStyle(
                                vm.occasion == context ? Color.dsDeepSlate : Color.dsTextSecondary
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(vm.occasion == context ? Color.dsAccentGold : Color.dsSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(
                                        Color.dsAccentGold.opacity(vm.occasion == context ? 0 : 0.3),
                                        lineWidth: 0.5
                                    )
                            )
                        }
                        .animation(.dsDefault, value: vm.occasion)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // ── Content section ───────────────────────────────────────────────────────

    @ViewBuilder
    private var contentSection: some View {
        if vm.isLoading {
            LuxuryLoadingView()
                .transition(.opacity)

        } else if let err = vm.currentError {
            LuxuryErrorView(error: err) {
                Task {
                    guard let p = profile else { return }
                    await vm.generateOutfit(profile: p,
                                            activeItems: activeItems,
                                            history: history)
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.96)))

        } else if let suggestion = vm.suggestion {
            VStack(spacing: 12) {
                if vm.isOfflineSuggestion { offlineBanner }
                OutfitSuggestionCard(response: suggestion, items: activeItems)
                usarOutfitButton
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))

        } else {
            emptyState
                .transition(.opacity)
        }
    }

    // ── Offline banner ────────────────────────────────────────────────────────

    private var offlineBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.caption)
                .foregroundStyle(Color.dsAccentGold.opacity(0.65))
            Text(Strings.styleOfflineMode)
                .font(.dsCaption)
                .foregroundStyle(Color.dsTextTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.dsSurface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.dsAccentGold.opacity(0.18), lineWidth: 0.5)
        )
    }

    // ── Save button ───────────────────────────────────────────────────────────

    @ViewBuilder
    private var usarOutfitButton: some View {
        if vm.outfitSaved {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.dsAccentGold)
                Text(Strings.styleOutfitRegistered)
                    .font(.dsBodyMedium)
                    .foregroundStyle(Color.dsAccentGold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.dsAccentGold.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.dsAccentGold.opacity(0.3), lineWidth: 0.5)
            )
            .transition(.scale.combined(with: .opacity))
        } else {
            Button {
                withAnimation(.dsSpring) { vm.saveOutfit(to: ctx) }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                    Text(Strings.styleOutfitSave)
                }
                .font(.dsBodyMedium)
                .foregroundStyle(Color.dsDeepSlate)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.dsAccentGold)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.dsAccentGold.opacity(0.35), radius: 12, y: 6)
            }
            .transition(.opacity)
        }
    }

    // ── Empty state ───────────────────────────────────────────────────────────

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 44))
                .foregroundStyle(Color.dsAccentGold.opacity(0.45))

            VStack(spacing: 6) {
                Text(Strings.styleEmptyTitle)
                    .font(.dsTitle2)
                    .foregroundStyle(Color.dsTextSecondary)
                    .tracking(2)
                Text(Strings.styleEmptySubtitle)
                    .font(.dsBody)
                    .foregroundStyle(Color.dsTextTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 72)
    }
}
