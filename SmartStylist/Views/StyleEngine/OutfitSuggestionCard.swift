import SwiftUI

struct OutfitSuggestionCard: View {
    let response: StyleResponse
    let items: [ClothingItem]

    private func item(for id: UUID?) -> ClothingItem? {
        guard let id else { return nil }
        return items.first { $0.id == id }
    }

    var body: some View {
        LuxuryCard {
            VStack(alignment: .leading, spacing: 20) {
                Text(response.analisisContexto)
                    .font(.dsBody)
                    .foregroundStyle(Color.dsTextSecondary)

                GoldDivider()

                outfitGrid

                GoldDivider()

                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(Color.dsAccentGold)
                    Text(response.consejoEstilo)
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsTextSecondary)
                        .italic()
                }
            }
            .padding(20)
        }
    }

    private var outfitGrid: some View {
        let slots: [(String, UUID?)] = [
            ("Top",       response.outfitSugerido.superior),
            ("Bottom",    response.outfitSugerido.inferior),
            ("Shoes",     response.outfitSugerido.calzado),
            ("Outerwear", response.outfitSugerido.abrigo)
        ]
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(slots, id: \.0) { label, id in
                if let id, let clothingItem = item(for: id) {
                    VStack(spacing: 6) {
                        SilhouetteView(category: clothingItem.category, size: 60)
                        Text(label)
                            .font(.dsCaption)
                            .foregroundStyle(Color.dsTextTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.dsSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }
}
