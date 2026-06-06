import SwiftUI
import SwiftData

struct VirtualClosetView: View {
    @Query private var allItems: [ClothingItem]
    @Environment(\.modelContext) private var ctx
    @State private var vm = ClosetViewModel()
    @State private var showAddItem = false
    @State private var itemToDispose: ClothingItem?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.dsDeepSlate.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        categoryFilter
                        statusSummary
                        itemGrid
                    }
                    .padding(16)
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
                        .foregroundStyle(Color.dsAccentGold)
                        .tracking(3)
                }
            }
            .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
            .searchable(text: $vm.searchText, prompt: Strings.wardrobeSearchPlaceholder)
            .sheet(isPresented: $showAddItem) { AddItemView() }
            .sheet(item: $itemToDispose) { item in DisposeItemSheet(item: item) }
        }
    }

    // ── Subviews ──────────────────────────────────────────────────────────────

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SelectionChip(label: Strings.wardrobeFilterAll,
                              isSelected: vm.selectedCategory == nil) {
                    vm.selectedCategory = nil
                }
                ForEach(ClothingCategory.allCases, id: \.self) { cat in
                    SelectionChip(label: cat.localizedName,
                                  isSelected: vm.selectedCategory == cat) {
                        vm.selectedCategory = cat
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

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

    private var itemGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(vm.filteredItems(from: allItems)) { item in
                NavigationLink(destination: ItemDetailView(item: item)) {
                    ClothingItemCard(
                        item: item,
                        onDispose: { itemToDispose = item },
                        onArchive: { vm.archiveItem(item, context: ctx) },
                        onRestore: { vm.restoreItem(item, context: ctx) }
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var addButton: some View {
        Button { showAddItem = true } label: {
            Image(systemName: "plus")
                .foregroundStyle(Color.dsDeepSlate)
                .font(.title2.weight(.semibold))
                .padding(18)
                .background(Color.dsAccentGold)
                .clipShape(Circle())
                .shadow(color: Color.dsAccentGold.opacity(0.4), radius: 12, y: 6)
        }
    }
}
