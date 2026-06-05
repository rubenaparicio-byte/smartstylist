import SwiftUI
import SwiftData

struct VirtualClosetView: View {
    @Query private var allItems: [ClothingItem]
    @Environment(\.modelContext) private var ctx
    @State private var vm = ClosetViewModel()
    @State private var showAddItem = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Color.dsDeepSlate.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        categoryFilter
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
                    Text("WARDROBE")
                        .font(.dsTitle2)
                        .foregroundStyle(Color.dsAccentGold)
                        .tracking(3)
                }
            }
            .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
            .searchable(text: $vm.searchText, prompt: "Search pieces…")
            .sheet(isPresented: $showAddItem) { AddItemView() }
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SelectionChip(label: "All", isSelected: vm.selectedCategory == nil) {
                    vm.selectedCategory = nil
                }
                ForEach(ClothingCategory.allCases, id: \.self) { cat in
                    SelectionChip(label: cat.rawValue.capitalized,
                                  isSelected: vm.selectedCategory == cat) {
                        vm.selectedCategory = cat
                    }
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var itemGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(vm.filteredItems(from: allItems)) { item in
                NavigationLink(destination: ItemDetailView(item: item)) {
                    ClothingItemCard(item: item) {
                        vm.disposeItem(item, context: ctx)
                    }
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
