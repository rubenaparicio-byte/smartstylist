import SwiftUI
import SwiftData

struct InstantLookView: View {
    @Query private var allItems: [ClothingItem]
    @Query private var history: [OutfitHistory]
    @Query private var profiles: [UserProfile]
    @Query(sort: \PlannedLook.scheduledDate) private var plannedLooks: [PlannedLook]
    @Environment(\.modelContext) private var modelContext

    @State private var vm = StyleEngineViewModel()
    @State private var selectedOccasion: EventContext = .casualWeekend
    @State private var generationTask: Task<Void, Never>?
    @State private var savedToCalendar = false

    private var activeItems: [ClothingItem] { allItems.filter { $0.status == .active } }
    private var profile: UserProfile? { profiles.first(where: { $0.onboardingCompleted }) }

    private var todayLook: PlannedLook? {
        plannedLooks.first { Calendar.current.isDateInToday($0.scheduledDate) }
    }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            RadialGradient(
                colors: [Color.dsAccentPrimary.opacity(0.12), .clear],
                center: .top, startRadius: 0, endRadius: 300
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(Strings.instantOccasion)
                            .font(.dsLabel)
                            .foregroundStyle(Color.dsTextSecondary)
                            .tracking(2)
                        Text(Strings.instantSubtitle)
                            .font(.dsCaption)
                            .foregroundStyle(Color.dsTextTertiary)
                    }

                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())],
                        spacing: 10
                    ) {
                        ForEach(EventContext.allCases, id: \.self) { eventCtx in
                            InstantOccasionChip(
                                context: eventCtx,
                                isSelected: selectedOccasion == eventCtx
                            ) {
                                HapticManager.impact(.light)
                                selectedOccasion = eventCtx
                                vm.suggestion = nil
                                savedToCalendar = false
                            }
                        }
                    }

                    Button {
                        generationTask?.cancel()
                        generationTask = Task { await generateNow() }
                    } label: {
                        HStack(spacing: 8) {
                            if vm.isLoading {
                                ProgressView()
                                    .tint(Color.dsBackground)
                                    .scaleEffect(0.85)
                            } else {
                                Image(systemName: "bolt.fill")
                            }
                            Text(vm.isLoading ? Strings.instantGenerating : Strings.instantGenerate)
                        }
                        .font(.dsBodyMedium)
                        .foregroundStyle(Color.dsBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color.dsAccentPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .shadow(color: Color.dsAccentPrimary.opacity(0.40), radius: 14, y: 7)
                    }
                    .disabled(vm.isLoading || profile == nil)
                    .animation(.dsFast, value: vm.isLoading)

                    if let suggestion = vm.suggestion {
                        VStack(spacing: 12) {
                            OutfitSuggestionCard(response: suggestion, items: activeItems)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))

                            if savedToCalendar {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Color.dsAccentPrimary)
                                    Text(Strings.instantSavedToCalendar)
                                        .font(.dsBodyMedium)
                                        .foregroundStyle(Color.dsAccentPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.dsAccentPrimary.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(Color.dsAccentPrimary.opacity(0.30), lineWidth: 0.5)
                                )
                                .transition(.scale.combined(with: .opacity))
                            } else {
                                Button {
                                    saveToToday(suggestion)
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "calendar.badge.plus")
                                        Text(Strings.instantSaveToCalendar)
                                    }
                                    .font(.dsBodyMedium)
                                    .foregroundStyle(Color.dsAccentPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(Color.dsAccentPrimary.opacity(0.10))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.dsAccentPrimary.opacity(0.30), lineWidth: 0.5)
                                    )
                                }
                                .transition(.opacity)
                            }
                        }
                        .animation(.dsSpring, value: savedToCalendar)
                    }
                }
                .padding(16)
                .padding(.bottom, 32)
                .animation(.dsDefault, value: vm.suggestion != nil)
            }
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 90) }
        }
        .onDisappear { generationTask?.cancel() }
    }

    private func generateNow() async {
        guard let p = profile else { return }
        vm.occasion = selectedOccasion
        savedToCalendar = false
        HapticManager.impact(.rigid)
        await vm.generateOutfit(profile: p, activeItems: activeItems, history: history)
        HapticManager.notification(vm.currentError != nil ? .error : .success)
    }

    private func saveToToday(_ suggestion: StyleResponse) {
        HapticManager.impact(.medium)
        let today = Calendar.current.startOfDay(for: .now)

        if let existing = todayLook {
            existing.styleResponse = suggestion
            existing.itemIds = suggestion.outfitSugerido.allItemIds
            existing.isInstant = true
        } else {
            let look = PlannedLook(
                scheduledDate: today,
                occasionRaw: selectedOccasion.rawValue,
                isInstant: true
            )
            look.styleResponse = suggestion
            look.itemIds = suggestion.outfitSugerido.allItemIds
            look.weatherContext = vm.currentWeather?.displayString
            modelContext.insert(look)
        }

        try? modelContext.save()
        withAnimation(.dsSpring) { savedToCalendar = true }
    }
}

// ── InstantOccasionChip ───────────────────────────────────────────────────────

private struct InstantOccasionChip: View {
    let context: EventContext
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: context.icon)
                    .font(.system(size: 22, weight: .medium))
                Text(context.localizedName)
                    .font(.system(size: 11, weight: .medium))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(
                isSelected ? Color.dsBackground : Color.dsTextSecondary
            )
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                isSelected
                    ? AnyShapeStyle(Color.dsAccentPrimary)
                    : AnyShapeStyle(Material.ultraThinMaterial)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.dsAccentPrimary.opacity(isSelected ? 0 : 0.25), lineWidth: 0.5)
            )
        }
        .animation(.dsSpring, value: isSelected)
    }
}
