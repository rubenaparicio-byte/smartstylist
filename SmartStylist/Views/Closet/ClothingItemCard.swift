import SwiftUI

struct ClothingItemCard: View {
    let item: ClothingItem
    var onDispose: (() -> Void)? = nil
    var onArchive: (() -> Void)? = nil
    var onRestore: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            thumbnail
            categoryBadge
            if item.status == .archived { archivedBadge }
        }
        .frame(height: 160)
        .luxuryCard(cornerRadius: 16)
        .opacity(item.status == .archived ? 0.65 : 1.0)
        .contextMenu { contextMenuItems }
    }

    // ── Subviews ──────────────────────────────────────────────────────────────

    @ViewBuilder
    private var thumbnail: some View {
        if let path = item.imagePath, let uiImage = UIImage(contentsOfFile: path) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else {
            Color.dsSurface
            SilhouetteView(category: item.category, size: 60)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var categoryBadge: some View {
        VStack {
            Spacer()
            HStack {
                Text(item.category.rawValue.capitalized)
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsTextSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Material.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Spacer()
            }
            .padding(8)
        }
    }

    private var archivedBadge: some View {
        VStack {
            HStack {
                Spacer()
                Text("ARCHIVED")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundStyle(Color.dsTextTertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Material.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    .padding(8)
            }
            Spacer()
        }
    }

    @ViewBuilder
    private var contextMenuItems: some View {
        if item.status == .active, let onArchive {
            Button { onArchive() } label: {
                Label("Archive", systemImage: "archivebox")
            }
        }
        if item.status == .archived, let onRestore {
            Button { onRestore() } label: {
                Label("Restore to Active", systemImage: "arrow.uturn.up")
            }
        }
        if let onDispose {
            Button(role: .destructive) { onDispose() } label: {
                Label("Retire this piece", systemImage: "trash")
            }
        }
    }
}
