import SwiftUI
import SwiftData

struct StyleEngineView: View {
    @Query(filter: #Predicate<ClothingItem> { $0.status == "active" })
    private var activeItems: [ClothingItem]

    @Query private var history: [OutfitHistory]
    @Query private var profiles: [UserProfile]
    @State private var vm = StyleEngineViewModel()

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

                        occasionPicker

                        if let suggestion = vm.suggestion {
                            OutfitSuggestionCard(response: suggestion, items: activeItems)
                        } else if vm.isLoading {
                            loadingState
                        } else {
                            emptyState
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Style")
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
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.dsAccentGold)
                    }
                }
            }
            .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .task {
                guard let p = profile, vm.suggestion == nil else { return }
                await vm.generateOutfit(profile: p, activeItems: activeItems, history: history)
            }
        }
    }

    private var occasionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(["Daily", "Work", "Casual", "Formal", "Sport", "Evening"], id: \.self) { occ in
                    SelectionChip(label: occ, isSelected: vm.occasion == occ) {
                        vm.occasion = occ
                    }
                }
            }
        }
    }

    private var loadingState: some View {
        HStack {
            Spacer()
            VStack(spacing: 16) {
                LoadingPulse()
                Text("Curating your look…")
                    .font(.dsBody)
                    .foregroundStyle(Color.dsTextSecondary)
            }
            Spacer()
        }
        .padding(.top, 80)
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 12) {
                Image(systemName: "tshirt")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.dsAccentGold.opacity(0.4))
                Text("Tap ↻ to generate today's look")
                    .font(.dsBody)
                    .foregroundStyle(Color.dsTextTertiary)
            }
            Spacer()
        }
        .padding(.top, 80)
    }
}
