import SwiftUI

struct ItemDetailView: View {
    let item: ClothingItem
    @Environment(\.modelContext) private var ctx
    @State private var vm = ClosetViewModel()
    @State private var showDisposeSheet = false

    var body: some View {
        ZStack {
            Color.dsBackground.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 24) {
                SilhouetteView(category: item.category, size: 160)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 32)

                LuxuryCard {
                    VStack(alignment: .leading, spacing: 12) {
                        detailRow(label: "Category", value: item.category.rawValue.capitalized)
                        detailRow(label: "Style",    value: item.style)
                        detailRow(label: "Colour",   value: item.primaryColor)
                        detailRow(label: "Status",   value: item.status.rawValue.capitalized)
                        if !item.disposeReason.isEmpty {
                            detailRow(label: "Retired",  value: item.disposeReason.capitalized)
                        }
                        if !item.tags.isEmpty {
                            detailRow(label: "Tags", value: item.tags.joined(separator: ", "))
                        }
                    }
                    .padding(20)
                }
                .padding(.horizontal, 16)

                Spacer()

                actionButtons
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
            }
        }
        .navigationTitle("Item Detail")
        .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
        .sheet(isPresented: $showDisposeSheet) {
            DisposeItemSheet(item: item)
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        switch item.status {
        case .active:
            VStack(spacing: 10) {
                Button { vm.archiveItem(item, context: ctx) } label: {
                    Label("Archive", systemImage: "archivebox")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.dsSurface)
                        .foregroundStyle(Color.dsTextSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                Button(role: .destructive) { showDisposeSheet = true } label: {
                    Label("Retire this piece", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.dsErrorRed.opacity(0.15))
                        .foregroundStyle(Color.dsErrorRed)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }

        case .archived:
            VStack(spacing: 10) {
                Button { vm.restoreItem(item, context: ctx) } label: {
                    Label("Restore to Active", systemImage: "arrow.uturn.up")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.dsAccentPrimary)
                        .foregroundStyle(Color.dsBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                Button(role: .destructive) { showDisposeSheet = true } label: {
                    Label("Retire this piece", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.dsErrorRed.opacity(0.15))
                        .foregroundStyle(Color.dsErrorRed)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }

        case .disposed:
            EmptyView()
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label).font(.dsCaption).foregroundStyle(Color.dsTextTertiary)
            Spacer()
            Text(value).font(.dsBody).foregroundStyle(Color.dsTextPrimary)
        }
    }
}
