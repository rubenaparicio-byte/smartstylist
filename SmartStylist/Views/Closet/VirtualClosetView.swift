import SwiftUI
import SwiftData

struct VirtualClosetView: View {
    @Query private var allItems: [ClothingItem]
    @Environment(\.modelContext) private var ctx
    @State private var vm = ClosetViewModel()
    @State private var showAddItem = false
    @State private var itemToDispose: ClothingItem?
    @State private var showFilters = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.dsBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        searchRow
                        if showFilters {
                            filterPanel
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                        categoryFilter
                        statusSummary
                        gridSection
                    }
                    .padding(16)
                    .animation(.dsDefault, value: showFilters)
                    .animation(.easeInOut(duration: 0.22), value: filterKey)
                }

                addButton
                    .padding(24)
            }
            .navigationTitle("Wardrobe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(Strings.wardrobeNavTitle)
                        .font(.dsTitle2)
                        .foregroundStyle(Color.dsAccentPrimary)
                        .tracking(3)
                }
            }
            .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
            .sheet(isPresented: $showAddItem) { AddItemView() }
            .sheet(item: $itemToDispose) { item in DisposeItemSheet(item: item) }
        }
    }

    // ── Animation key ─────────────────────────────────────────────────────────
    // Changes whenever any filter-driving state changes, triggering grid animation.

    private var filterKey: String {
        "\(vm.searchText)|\(vm.selectedCategory?.rawValue ?? "")|" +
        "\(vm.selectedStyles.sorted().joined(separator: ","))|\(vm.selectedPattern ?? "")|\(vm.showOnlyStatus?.rawValue ?? "")"
    }

    // ── Search Row ────────────────────────────────────────────────────────────

    private var searchRow: some View {
        HStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundStyle(vm.searchText.isEmpty ? Color.dsTextTertiary : Color.dsAccentPrimary)
                    .animation(.dsDefault, value: vm.searchText.isEmpty)

                TextField(Strings.wardrobeSearchPlaceholder, text: $vm.searchText)
                    .font(.dsBody)
                    .foregroundStyle(Color.dsTextPrimary)
                    .autocorrectionDisabled()
                    .tint(Color.dsAccentPrimary)

                if !vm.searchText.isEmpty {
                    Button { vm.searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.dsTextTertiary)
                    }
                    .transition(.opacity)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(Color.dsCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        vm.searchText.isEmpty
                            ? Color.dsAccentPrimary.opacity(0.12)
                            : Color.dsAccentPrimary.opacity(0.55),
                        lineWidth: 0.5
                    )
                    .animation(.dsDefault, value: vm.searchText.isEmpty)
            )

            // Filter toggle button with active-filters badge
            Button {
                withAnimation(.dsDefault) { showFilters.toggle() }
            } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: showFilters
                          ? "line.3.horizontal.decrease.circle.fill"
                          : "line.3.horizontal.decrease.circle")
                        .font(.title3)
                        .foregroundStyle(showFilters || vm.hasActiveFilters
                                         ? Color.dsAccentPrimary : Color.dsTextSecondary)
                        .contentTransition(.symbolEffect(.replace.offUp))
                    if vm.hasActiveFilters {
                        Circle()
                            .fill(Color.dsAccentPrimary)
                            .frame(width: 7, height: 7)
                            .offset(x: 2, y: -2)
                    }
                }
                .frame(width: 38, height: 38)
                .animation(.dsDefault, value: vm.hasActiveFilters)
            }
        }
    }

    // ── Filter Panel ──────────────────────────────────────────────────────────

    private var filterPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            filterSection(title: Strings.filterSectionStatus) {
                HStack(spacing: 8) {
                    SelectionChip(label: Strings.filterStatusActive,
                                  isSelected: vm.showOnlyStatus == .active) {
                        withAnimation(.dsDefault) {
                            vm.showOnlyStatus = vm.showOnlyStatus == .active ? nil : .active
                        }
                    }
                    SelectionChip(label: Strings.filterStatusArchived,
                                  isSelected: vm.showOnlyStatus == .archived) {
                        withAnimation(.dsDefault) {
                            vm.showOnlyStatus = vm.showOnlyStatus == .archived ? nil : .archived
                        }
                    }
                }
            }

            AccentDivider()

            filterSection(title: Strings.filterSectionStyles) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ClosetViewModel.knownStyles, id: \.self) { style in
                            SelectionChip(label: style,
                                          isSelected: vm.selectedStyles.contains(style)) {
                                withAnimation(.dsDefault) {
                                    if vm.selectedStyles.contains(style) {
                                        vm.selectedStyles.remove(style)
                                    } else {
                                        vm.selectedStyles.insert(style)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            AccentDivider()

            filterSection(title: Strings.filterSectionPatterns) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(ClosetViewModel.knownPatterns.prefix(4), id: \.self) { pattern in
                            SelectionChip(label: pattern,
                                          isSelected: vm.selectedPattern == pattern) {
                                withAnimation(.dsDefault) {
                                    vm.selectedPattern = vm.selectedPattern == pattern ? nil : pattern
                                }
                            }
                        }
                    }
                }
            }

            if vm.hasActiveFilters {
                Button {
                    withAnimation(.dsDefault) { vm.clearFilters() }
                } label: {
                    Text(Strings.filterClearAll)
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsAccentPrimary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        }
        .padding(14)
        .background(Material.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.dsAccentPrimary.opacity(0.18), lineWidth: 0.5)
        )
    }

    @ViewBuilder
    private func filterSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.dsCaption)
                .foregroundStyle(Color.dsTextTertiary)
                .tracking(2)
            content()
        }
    }

    // ── Category Filter ───────────────────────────────────────────────────────

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SelectionChip(label: Strings.wardrobeFilterAll,
                              isSelected: vm.selectedCategory == nil) {
                    withAnimation(.dsDefault) { vm.selectedCategory = nil }
                }
                ForEach(ClothingCategory.allCases, id: \.self) { cat in
                    SelectionChip(label: cat.localizedName,
                                  isSelected: vm.selectedCategory == cat) {
                        withAnimation(.dsDefault) { vm.selectedCategory = cat }
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // ── Status Summary ────────────────────────────────────────────────────────

    @ViewBuilder
    private var statusSummary: some View {
        let visible       = vm.visibleItems(from: allItems)
        let activeCount   = visible.filter { $0.status == .active }.count
        let archivedCount = visible.filter { $0.status == .archived }.count
        if archivedCount > 0 {
            HStack(spacing: 4) {
                Text("\(activeCount) \(Strings.wardrobeStatusActive)")
                    .foregroundStyle(Color.dsTextSecondary)
                Text("·")
                    .foregroundStyle(Color.dsTextTertiary)
                Text("\(archivedCount) \(Strings.wardrobeStatusArchived)")
                    .foregroundStyle(Color.dsTextTertiary)
            }
            .font(.dsCaption)
            .padding(.leading, 2)
        }
    }

    // ── Grid Section ──────────────────────────────────────────────────────────

    @ViewBuilder
    private var gridSection: some View {
        let filtered = vm.filteredItems(from: allItems)
        let hasActiveQuery = !vm.searchText.isEmpty || vm.hasActiveFilters || vm.selectedCategory != nil
        if filtered.isEmpty && hasActiveQuery {
            noResultsView
                .transition(.opacity)
        } else {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(filtered) { item in
                    NavigationLink(destination: ItemDetailView(item: item)) {
                        ClothingItemCard(
                            item: item,
                            onDispose: { itemToDispose = item },
                            onArchive: { vm.archiveItem(item, context: ctx) },
                            onRestore: { vm.restoreItem(item, context: ctx) }
                        )
                    }
                    .buttonStyle(CardPressStyle())
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
        }
    }

    // ── No Results ────────────────────────────────────────────────────────────

    private var noResultsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .thin))
                .foregroundStyle(Color.dsTextTertiary)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 8) {
                Text(Strings.filterNoResultsTitle)
                    .font(.dsTitle2)
                    .foregroundStyle(Color.dsTextPrimary)
                    .tracking(2)
                Text(Strings.filterNoResultsSubtitle)
                    .font(.dsBody)
                    .foregroundStyle(Color.dsTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                withAnimation(.dsDefault) { vm.clearFilters() }
            } label: {
                Text(Strings.filterClearAll)
                    .font(.dsBodyMedium)
                    .foregroundStyle(Color.dsBackground)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.dsAccentPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(.vertical, 48)
        .frame(maxWidth: .infinity)
    }

    // ── Add Button ────────────────────────────────────────────────────────────

    private var addButton: some View {
        Button { showAddItem = true } label: {
            Image(systemName: "plus")
                .foregroundStyle(Color.dsBackground)
                .font(.title2.weight(.semibold))
                .padding(18)
                .background(Color.dsAccentPrimary)
                .clipShape(Circle())
                .shadow(color: Color.dsAccentPrimary.opacity(0.4), radius: 12, y: 6)
        }
    }
}
