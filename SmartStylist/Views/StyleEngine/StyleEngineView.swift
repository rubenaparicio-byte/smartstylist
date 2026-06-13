import SwiftUI
import SwiftData

struct StyleEngineView: View {
    @Query private var allItems: [ClothingItem]
    @Query private var history: [OutfitHistory]
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var ctx
    @State private var vm = StyleEngineViewModel()
    @State private var shareImage: Image?

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
                Color.dsBackground.ignoresSafeArea()

                RadialGradient(
                    colors: [Color.dsAccentPrimary.opacity(0.12), .clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 320
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)

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
                        .foregroundStyle(Color.dsAccentPrimary)
                        .tracking(3)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            guard let p = profile else { return }
                            await generateWithHaptics(profile: p)
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.dsAccentPrimary)
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
                await generateWithHaptics(profile: p, rigid: false)
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
                                vm.occasion == context ? Color.dsBackground : Color.dsTextSecondary
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(vm.occasion == context ? Color.dsAccentPrimary : Color.dsSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(
                                        Color.dsAccentPrimary.opacity(vm.occasion == context ? 0 : 0.3),
                                        lineWidth: 0.5
                                    )
                            )
                        }
                        .animation(.dsSpring, value: vm.occasion)
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
                    await generateWithHaptics(profile: p)
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.96)))

        } else if let suggestion = vm.suggestion {
            VStack(spacing: 12) {
                if vm.isOfflineSuggestion { offlineBanner }
                OutfitSuggestionCard(response: suggestion, items: activeItems)
                usarOutfitButton
                shareButton
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
            .onAppear { renderShareImage(suggestion: suggestion) }

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
                .foregroundStyle(Color.dsAccentPrimary.opacity(0.65))
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
                .stroke(Color.dsAccentPrimary.opacity(0.18), lineWidth: 0.5)
        )
    }

    // ── Save button ───────────────────────────────────────────────────────────

    @ViewBuilder
    private var usarOutfitButton: some View {
        if vm.outfitSaved {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.dsAccentPrimary)
                Text(Strings.styleOutfitRegistered)
                    .font(.dsBodyMedium)
                    .foregroundStyle(Color.dsAccentPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.dsAccentPrimary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.dsAccentPrimary.opacity(0.3), lineWidth: 0.5)
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
                .foregroundStyle(Color.dsBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.dsAccentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .shadow(color: Color.dsAccentPrimary.opacity(0.35), radius: 12, y: 6)
            }
            .transition(.opacity)
        }
    }

    // ── Share ─────────────────────────────────────────────────────────────────

    private func renderShareImage(suggestion: StyleResponse) {
        let card = OutfitSuggestionCard(response: suggestion, items: activeItems)
            .frame(width: 360)
            .padding(16)
            .background(Color.dsBackground)
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3   // 3× for crisp sharing regardless of device density
        shareImage = renderer.uiImage.map { Image(uiImage: $0) }
    }

    @ViewBuilder
    private var shareButton: some View {
        if let image = shareImage {
            ShareLink(
                item: image,
                preview: SharePreview(Strings.shareOutfitMessage, image: image)
            ) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                    Text(Strings.shareOutfitButton)
                }
                .font(.dsBodyMedium)
                .foregroundStyle(Color.dsAccentPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.dsAccentPrimary.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.dsAccentPrimary.opacity(0.35), lineWidth: 0.5)
                )
            }
        }
    }

    // ── Haptic-aware generate ─────────────────────────────────────────────────

    private func generateWithHaptics(profile: UserProfile, rigid: Bool = true) async {
        if rigid { HapticManager.impact(.rigid) }
        await vm.generateOutfit(profile: profile, activeItems: activeItems, history: history)
        if vm.currentError != nil {
            HapticManager.notification(.error)
        } else {
            HapticManager.notification(.success)
        }
    }

    // ── Empty state ───────────────────────────────────────────────────────────

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 44))
                .foregroundStyle(Color.dsAccentPrimary.opacity(0.45))
                .symbolRenderingMode(.hierarchical)
                .symbolEffect(.pulse, options: .repeating)

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
