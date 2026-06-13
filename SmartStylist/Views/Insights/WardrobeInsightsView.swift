import Charts
import SwiftUI
import SwiftData

struct WardrobeInsightsView: View {
    @Query private var allItems: [ClothingItem]
    @Query private var history: [OutfitHistory]
    @State private var vm = InsightsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground.ignoresSafeArea()

                if allItems.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            styleDistributionCard
                                .scrollTransition(.animated) { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1.0 : 0.0)
                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.92)
                                        .offset(y: phase.isIdentity ? 0.0 : 20.0)
                                }
                            topWornCard
                                .scrollTransition(.animated) { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1.0 : 0.0)
                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.92)
                                        .offset(y: phase.isIdentity ? 0.0 : 20.0)
                                }
                            closetHealthCard
                                .scrollTransition(.animated) { content, phase in
                                    content
                                        .opacity(phase.isIdentity ? 1.0 : 0.0)
                                        .scaleEffect(phase.isIdentity ? 1.0 : 0.92)
                                        .offset(y: phase.isIdentity ? 0.0 : 20.0)
                                }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle(Strings.insightsNavTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(Strings.insightsNavTitle)
                        .font(.dsTitle2)
                        .foregroundStyle(Color.dsAccentPrimary)
                        .tracking(3)
                }
            }
            .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
        }
    }

    // ── Style Distribution (Donut chart) ──────────────────────────────────────

    private var styleDistributionCard: some View {
        let distribution = vm.styleDistribution(from: allItems)
        return VStack(alignment: .leading, spacing: 16) {
            sectionHeader(Strings.insightsStyleTitle)

            if distribution.isEmpty {
                emptyNote
            } else {
                Chart(distribution) { entry in
                    SectorMark(
                        angle: .value("Items", entry.count),
                        innerRadius: .ratio(0.56),
                        angularInset: 2
                    )
                    .foregroundStyle(Color(hex: entry.chartColorHex))
                    .cornerRadius(4)
                }
                .chartLegend(.hidden)
                .chartPlotStyle { $0.background(Color.clear) }
                .frame(height: 200)

                // Custom legend
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(distribution) { entry in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color(hex: entry.chartColorHex))
                                .frame(width: 10, height: 10)
                            Text(entry.style)
                                .font(.dsCaption)
                                .foregroundStyle(Color.dsTextSecondary)
                                .lineLimit(1)
                            Spacer()
                            Text("\(entry.count)")
                                .font(.dsLabel)
                                .foregroundStyle(Color.dsAccentPrimary)
                                .contentTransition(.numericText(value: Double(entry.count)))
                                .animation(.dsDefault, value: entry.count)
                        }
                    }
                }
            }
        }
        .padding(18)
        .luxuryCard()
    }

    // ── Top Worn Items ────────────────────────────────────────────────────────

    private var topWornCard: some View {
        let topItems = vm.topWornItems(from: allItems, history: history)
        return VStack(alignment: .leading, spacing: 14) {
            sectionHeader(Strings.insightsTopTitle)

            if topItems.isEmpty {
                emptyNote
            } else {
                ForEach(Array(topItems.enumerated()), id: \.element.id) { rank, entry in
                    topWornRow(rank: rank + 1, entry: entry)
                    if rank < topItems.count - 1 { AccentDivider() }
                }
            }
        }
        .padding(18)
        .luxuryCard()
    }

    private func topWornRow(rank: Int, entry: InsightsViewModel.TopItem) -> some View {
        HStack(spacing: 14) {
            Text("#\(rank)")
                .font(.dsTitle2)
                .foregroundStyle(rank == 1 ? Color.dsAccentPrimary : Color.dsTextTertiary)
                .frame(width: 32, alignment: .leading)

            VStack(alignment: .leading, spacing: 3) {
                Text(entry.item.category.localizedName)
                    .font(.dsBodyMedium)
                    .foregroundStyle(Color.dsTextPrimary)
                Text(entry.item.style)
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsTextSecondary)
            }

            Spacer()

            HStack(spacing: 4) {
                Text("\(entry.wearCount)")
                    .font(.dsBodyMedium)
                    .foregroundStyle(Color.dsAccentPrimary)
                    .contentTransition(.numericText(value: Double(entry.wearCount)))
                    .animation(.dsDefault, value: entry.wearCount)
                Text(Strings.insightsWorn)
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsTextTertiary)
            }
        }
    }

    // ── Closet Health ─────────────────────────────────────────────────────────

    private var closetHealthCard: some View {
        let health = vm.closetHealth(from: allItems)
        return VStack(alignment: .leading, spacing: 16) {
            sectionHeader(Strings.insightsHealthTitle)

            HStack(spacing: 10) {
                statPill(value: health.active,
                         label: Strings.insightsHealthActive,
                         hex: "#D4AF37")
                statPill(value: health.archived,
                         label: Strings.insightsHealthArchived,
                         hex: "#E9C46A")
                statPill(value: health.disposed,
                         label: Strings.insightsHealthDisposed,
                         hex: "#3A3A3C")
            }

            // Segmented proportion bar
            if health.total > 0 {
                GeometryReader { geo in
                    HStack(spacing: 2) {
                        if health.active > 0 {
                            Color.dsAccentPrimary
                                .frame(width: geo.size.width * CGFloat(health.active) / CGFloat(health.total))
                        }
                        if health.archived > 0 {
                            Color.dsAccentSecondary.opacity(0.65)
                                .frame(width: geo.size.width * CGFloat(health.archived) / CGFloat(health.total))
                        }
                        if health.disposed > 0 {
                            Color.dsSurface.opacity(0.9)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .frame(height: 7)
                .clipShape(Capsule())
            }

            if let reason = health.topDisposeReason,
               let label = DisposeReason(rawValue: reason)?.label {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                        .foregroundStyle(Color.dsTextTertiary)
                    Text(Strings.insightsMostDisposed(label))
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsTextTertiary)
                }
            }
        }
        .padding(18)
        .luxuryCard()
    }

    private func statPill(value: Int, label: String, hex: String) -> some View {
        VStack(spacing: 5) {
            Text("\(value)")
                .font(.dsTitle)
                .foregroundStyle(Color(hex: hex))
                .contentTransition(.numericText(value: Double(value)))
                .animation(.dsDefault, value: value)
            Text(label)
                .font(.dsCaption)
                .foregroundStyle(Color.dsTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.dsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // ── Empty / Helpers ───────────────────────────────────────────────────────

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(Color.dsTextTertiary)
            Text(Strings.insightsEmptyTitle)
                .font(.dsTitle2)
                .foregroundStyle(Color.dsTextPrimary)
                .tracking(2)
            Text(Strings.insightsEmptySubtitle)
                .font(.dsBody)
                .foregroundStyle(Color.dsTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    private var emptyNote: some View {
        Text(Strings.insightsEmptySubtitle)
            .font(.dsCaption)
            .foregroundStyle(Color.dsTextTertiary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.dsCaption)
            .foregroundStyle(Color.dsTextTertiary)
            .tracking(2)
    }
}
