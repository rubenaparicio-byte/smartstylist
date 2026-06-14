import SwiftUI
import SwiftData

struct LookPlannerView: View {
    @Query private var allItems: [ClothingItem]
    @Query private var history: [OutfitHistory]
    @Query private var profiles: [UserProfile]
    @Query(sort: \PlannedLook.scheduledDate) private var plannedLooks: [PlannedLook]
    @Environment(\.modelContext) private var modelContext

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: .now)
    @State private var vm = StyleEngineViewModel()
    @State private var generationTask: Task<Void, Never>?
    @State private var generatingForDate: Date?
    @State private var showAddEvent = false
    @State private var pendingOccasion: EventContext = .daily
    @State private var pendingVenueNote: String = ""

    private var activeItems: [ClothingItem] { allItems.filter { $0.status == .active } }
    private var profile: UserProfile? { profiles.first(where: { $0.onboardingCompleted }) }

    private var lookForSelectedDate: PlannedLook? {
        plannedLooks.first { Calendar.current.isDate($0.scheduledDate, inSameDayAs: selectedDate) }
    }

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()

            RadialGradient(
                colors: [Color.dsAccentPrimary.opacity(0.10), .clear],
                center: .top, startRadius: 0, endRadius: 280
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    WeekStripView(selectedDate: $selectedDate, plannedLooks: plannedLooks)

                    Group {
                        if vm.isLoading && generatingForDate == selectedDate {
                            LuxuryLoadingView()
                                .transition(.opacity)
                        } else if let look = lookForSelectedDate {
                            plannedDayContent(look: look)
                        } else {
                            emptyDayContent
                        }
                    }
                    .animation(.dsDefault, value: lookForSelectedDate?.id)
                    .animation(.dsDefault, value: vm.isLoading)
                }
                .padding(16)
                .padding(.bottom, 32)
            }
            .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 90) }
        }
        .sheet(isPresented: $showAddEvent) {
            AddEventSheet(
                date: selectedDate,
                selectedOccasion: $pendingOccasion,
                venueNote: $pendingVenueNote
            ) {
                showAddEvent = false
                Task { await generateForDay() }
            }
        }
        .onChange(of: selectedDate) { _, _ in
            generationTask?.cancel()
            vm.cancelGeneration()
            generatingForDate = nil
        }
        .onDisappear {
            generationTask?.cancel()
            vm.cancelGeneration()
        }
    }

    // ── Planned day content ───────────────────────────────────────────────────

    @ViewBuilder
    private func plannedDayContent(look: PlannedLook) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Event header
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: look.occasion.icon)
                        .font(.caption)
                        .foregroundStyle(Color.dsAccentPrimary)
                    Text(look.occasion.localizedName.uppercased())
                        .font(.dsLabel)
                        .foregroundStyle(Color.dsAccentPrimary)
                        .tracking(2)
                }
                if let note = look.venueNote, !note.isEmpty {
                    Text(note)
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsTextTertiary)
                }
            }

            if let response = look.styleResponse {
                OutfitSuggestionCard(response: response, items: activeItems)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                HStack(spacing: 12) {
                    Button {
                        generationTask?.cancel()
                        generationTask = Task { await regenerate(look: look) }
                    } label: {
                        Label(Strings.plannerRegenerate, systemImage: "arrow.clockwise")
                            .font(.dsLabel)
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

                    Button {
                        withAnimation(.dsDefault) { deleteLook(look) }
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(Color.dsTextTertiary)
                            .padding(14)
                            .background(Color.dsSurface.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            } else {
                generateButton(occasion: look.occasion, venueNote: look.venueNote)
            }
        }
    }

    // ── Empty day content ─────────────────────────────────────────────────────

    @ViewBuilder
    private var emptyDayContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(Color.dsAccentPrimary.opacity(0.45))
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 6) {
                Text(Strings.plannerEmptyTitle)
                    .font(.dsTitle2)
                    .foregroundStyle(Color.dsTextSecondary)
                    .tracking(2)
                Text(Strings.plannerEmptySubtitle)
                    .font(.dsBody)
                    .foregroundStyle(Color.dsTextTertiary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    pendingOccasion = .daily
                    pendingVenueNote = ""
                    generationTask?.cancel()
                    generationTask = Task { await generateForDay() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text(Strings.plannerQuickGenerate)
                    }
                    .font(.dsBodyMedium)
                    .foregroundStyle(Color.dsBackground)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.dsAccentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.dsAccentPrimary.opacity(0.35), radius: 12, y: 6)
                }

                Button {
                    pendingOccasion = .daily
                    pendingVenueNote = ""
                    showAddEvent = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                        Text(Strings.plannerAddEvent)
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
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    // ── Generate button (look exists but no outfit yet) ───────────────────────

    private func generateButton(occasion: EventContext, venueNote: String?) -> some View {
        Button {
            pendingOccasion = occasion
            pendingVenueNote = venueNote ?? ""
            generationTask?.cancel()
            generationTask = Task { await generateForDay() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text(Strings.plannerQuickGenerate)
            }
            .font(.dsBodyMedium)
            .foregroundStyle(Color.dsBackground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.dsAccentPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.dsAccentPrimary.opacity(0.35), radius: 12, y: 6)
        }
    }

    // ── Generation actions ────────────────────────────────────────────────────

    private func generateForDay() async {
        guard let p = profile else { return }
        vm.occasion = pendingOccasion
        generatingForDate = selectedDate
        HapticManager.impact(.rigid)

        await vm.generateOutfit(profile: p, activeItems: activeItems, history: history)
        HapticManager.notification(vm.currentError != nil ? .error : .success)

        generatingForDate = nil
        guard let suggestion = vm.suggestion else { return }

        let capturedDate = selectedDate
        let look: PlannedLook
        if let existing = plannedLooks.first(where: { Calendar.current.isDate($0.scheduledDate, inSameDayAs: capturedDate) }) {
            look = existing
        } else {
            look = PlannedLook(
                scheduledDate: capturedDate,
                occasionRaw: pendingOccasion.rawValue,
                venueNote: pendingVenueNote.isEmpty ? nil : pendingVenueNote
            )
            modelContext.insert(look)
        }

        look.styleResponse = suggestion
        look.itemIds = suggestion.outfitSugerido.allItemIds
        look.weatherContext = vm.currentWeather?.displayString
        try? modelContext.save()

        await NotificationService.shared.schedulePlannedLookReminder(for: look)
    }

    private func regenerate(look: PlannedLook) async {
        guard let p = profile else { return }
        vm.occasion = look.occasion
        generatingForDate = selectedDate
        HapticManager.impact(.rigid)

        await vm.generateOutfit(profile: p, activeItems: activeItems, history: history)
        HapticManager.notification(vm.currentError != nil ? .error : .success)

        generatingForDate = nil
        guard let suggestion = vm.suggestion else { return }

        look.styleResponse = suggestion
        look.itemIds = suggestion.outfitSugerido.allItemIds
        look.weatherContext = vm.currentWeather?.displayString
        try? modelContext.save()

        await NotificationService.shared.schedulePlannedLookReminder(for: look)
    }

    private func deleteLook(_ look: PlannedLook) {
        NotificationService.shared.cancelPlannedLookReminder(identifier: look.notificationIdentifier)
        modelContext.delete(look)
        try? modelContext.save()
    }
}

// ── WeekStripView ─────────────────────────────────────────────────────────────

private struct WeekStripView: View {
    @Binding var selectedDate: Date
    let plannedLooks: [PlannedLook]

    private let cal = Calendar.current

    private var days: [Date] {
        let today = cal.startOfDay(for: .now)
        return (-2...11).compactMap { cal.date(byAdding: .day, value: $0, to: today) }
    }

    private func hasLook(on date: Date) -> Bool {
        plannedLooks.contains { cal.isDate($0.scheduledDate, inSameDayAs: date) }
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(days, id: \.self) { date in
                        DayPillView(
                            date: date,
                            isToday: cal.isDateInToday(date),
                            isSelected: cal.isDate(date, inSameDayAs: selectedDate),
                            hasLook: hasLook(on: date)
                        ) {
                            HapticManager.impact(.light)
                            withAnimation(.dsSpring) { selectedDate = date }
                        }
                        .id(date)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
            .onAppear {
                let today = cal.startOfDay(for: .now)
                proxy.scrollTo(today, anchor: .leading)
            }
        }
    }
}

// ── DayPillView ───────────────────────────────────────────────────────────────

private struct DayPillView: View {
    let date: Date
    let isToday: Bool
    let isSelected: Bool
    let hasLook: Bool
    let action: () -> Void

    private var dayNumber: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "d"
        return fmt.string(from: date)
    }

    private var weekdayAbbrev: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return fmt.string(from: date).uppercased()
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(weekdayAbbrev)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(
                        isSelected ? Color.dsBackground : Color.dsTextTertiary
                    )

                Text(dayNumber)
                    .font(.system(size: 17, weight: isToday ? .bold : .medium))
                    .foregroundStyle(
                        isSelected
                            ? Color.dsBackground
                            : (isToday ? Color.dsAccentPrimary : Color.dsTextSecondary)
                    )

                Circle()
                    .fill(isSelected ? Color.dsBackground.opacity(0.7) : Color.dsAccentPrimary)
                    .frame(width: 5, height: 5)
                    .opacity(hasLook ? 1 : 0)
            }
            .frame(width: 48)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? AnyShapeStyle(Color.dsAccentPrimary)
                    : AnyShapeStyle(Color.dsSurface.opacity(isToday ? 0.7 : 0.3))
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isToday && !isSelected
                            ? Color.dsAccentPrimary.opacity(0.5)
                            : Color.dsAccentPrimary.opacity(isSelected ? 0 : 0.12),
                        lineWidth: isToday && !isSelected ? 1.0 : 0.5
                    )
            )
        }
        .animation(.dsSpring, value: isSelected)
    }
}

// ── AddEventSheet ─────────────────────────────────────────────────────────────

private struct AddEventSheet: View {
    let date: Date
    @Binding var selectedOccasion: EventContext
    @Binding var venueNote: String
    let onConfirm: () -> Void

    @Environment(\.dismiss) private var dismiss

    private var dateLabel: String {
        let fmt = DateFormatter()
        fmt.dateStyle = .full
        fmt.timeStyle = .none
        return fmt.string(from: date)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(Strings.plannerAddEventFor.uppercased())
                                .font(.dsLabel)
                                .foregroundStyle(Color.dsTextTertiary)
                                .tracking(2)
                            Text(dateLabel)
                                .font(.dsTitle2)
                                .foregroundStyle(Color.dsTextPrimary)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text(Strings.styleEventContext)
                                .font(.dsLabel)
                                .foregroundStyle(Color.dsTextSecondary)
                                .tracking(2)

                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 10
                            ) {
                                ForEach(EventContext.allCases, id: \.self) { eventCtx in
                                    Button {
                                        HapticManager.impact(.light)
                                        selectedOccasion = eventCtx
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: eventCtx.icon)
                                                .font(.system(size: 15, weight: .medium))
                                            Text(eventCtx.localizedName)
                                                .font(.dsLabel)
                                        }
                                        .foregroundStyle(
                                            selectedOccasion == eventCtx
                                                ? Color.dsBackground : Color.dsTextSecondary
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            selectedOccasion == eventCtx
                                                ? AnyShapeStyle(Color.dsAccentPrimary)
                                                : AnyShapeStyle(Material.ultraThinMaterial)
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .stroke(
                                                    Color.dsAccentPrimary.opacity(selectedOccasion == eventCtx ? 0 : 0.25),
                                                    lineWidth: 0.5
                                                )
                                        )
                                    }
                                    .animation(.dsSpring, value: selectedOccasion)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text(Strings.plannerVenueNote.uppercased())
                                .font(.dsLabel)
                                .foregroundStyle(Color.dsTextSecondary)
                                .tracking(2)

                            TextField(Strings.plannerVenuePlaceholder, text: $venueNote)
                                .font(.dsBody)
                                .foregroundStyle(Color.dsTextPrimary)
                                .padding(14)
                                .background(Color.dsSurface.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color.dsAccentPrimary.opacity(0.20), lineWidth: 0.5)
                                )
                        }

                        Button {
                            onConfirm()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "sparkles")
                                Text(Strings.plannerGenerateLook)
                            }
                            .font(.dsBodyMedium)
                            .foregroundStyle(Color.dsBackground)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.dsAccentPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color.dsAccentPrimary.opacity(0.35), radius: 12, y: 6)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(Strings.plannerAddEventTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(Strings.commonCancel) { dismiss() }
                        .foregroundStyle(Color.dsAccentPrimary)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
