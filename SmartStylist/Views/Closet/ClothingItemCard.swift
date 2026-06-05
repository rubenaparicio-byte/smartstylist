import SwiftUI

struct ClothingItemCard: View {
    let item: ClothingItem
    var onDispose: (() -> Void)? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let path = item.imagePath,
               let uiImage = UIImage(contentsOfFile: path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.dsSurface
                SilhouetteView(category: item.category, size: 60)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

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
        .frame(height: 160)
        .luxuryCard(cornerRadius: 16)
        .contextMenu {
            if let onDispose = onDispose {
                Button(role: .destructive) { onDispose() } label: {
                    Label("Retire this piece", systemImage: "trash")
                }
            }
        }
    }
}
