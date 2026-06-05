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
                }
            }
            .navigationTitle("Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("TODAY'S LOOK")
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
                        Image(systemName: vm.isLoading ? "arrow.clockwise" : "arrow.clockwise")
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
            .alert("Error", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { _ in vm.errorMessage = nil }
            )) {
                Button("Try Again") {
                    vm.errorMessage = nil
                    Task {
                        guard let p = profile else { return }
                        await vm.generateOutfit(profile: p, activeItems: activeItems, history: history)
                    }
                }
                Button("Cancel", role: .cancel) { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .task {
                guard let p = profile, vm.suggestion == nil, !vm.isLoading else { return }
                await vm.generateOutfit(profile: p, activeItems: activeItems, history: history)
            }
        }
    }

    // ── Event context picker ──────────────────────────────────────────────────

    private var eventContextPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("EVENT CONTEXT")
                .font(.dsLabel)
                .foregroundStyle(Color.dsTextSecondary)
                .tracking(2)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(EventContext.allCases, id: \.self) { ctx in
                        Button {
                            vm.occasion = ctx
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: ctx.icon).font(.caption)
                                Text(ctx.rawValue).font(.dsLabel)
                            }
                            .foregroundStyle(
                                vm.occasion == ctx ? Color.dsDeepSlate : Color.dsTextSecondary
                            )
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(vm.occasion == ctx ? Color.dsAccentGold : Color.dsSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(
                                        Color.dsAccentGold.opacity(vm.occasion == ctx ? 0 : 0.3),
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
            loadingState
        } else if let suggestion = vm.suggestion {
            OutfitSuggestionCard(response: suggestion, items: activeItems)
            usarOutfitButton
        } else {
            emptyState
        }
    }

    // ── "Usar Outfit Hoy" button ──────────────────────────────────────────────

    @ViewBuilder
    private var usarOutfitButton: some View {
        if vm.outfitSaved {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.dsAccentGold)
                Text("Outfit Registered for Today")
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
                    Text("Usar Outfit Hoy")
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

    // ── States ────────────────────────────────────────────────────────────────

    private var loadingState: some View {
        VStack(spacing: 16) {
            LoadingPulse()
            Text("Curating your look…")
                .font(.dsBody)
                .foregroundStyle(Color.dsTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 44))
                .foregroundStyle(Color.dsAccentGold.opacity(0.45))

            VStack(spacing: 6) {
                Text("YOUR LOOK AWAITS")
                    .font(.dsTitle2)
                    .foregroundStyle(Color.dsTextSecondary)
                    .tracking(2)
                Text("Tap ↻ to curate today's outfit")
                    .font(.dsBody)
                    .foregroundStyle(Color.dsTextTertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 72)
    }
}
