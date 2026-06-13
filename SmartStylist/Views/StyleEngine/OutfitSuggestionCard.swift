import SwiftUI

struct OutfitSuggestionCard: View {
    let response: StyleResponse
    let items: [ClothingItem]

    // ── Data helpers ──────────────────────────────────────────────────────────

    private struct LayerGroup: Identifiable {
        let layer: ThermalLayer
        let outfitItems: [ClothingItem]
        var id: String { layer.rawValue }
    }

    // Non-footwear items sorted outer→base
    private var layerGroups: [LayerGroup] {
        let ids = [
            response.outfitSugerido.superior,
            response.outfitSugerido.inferior,
            response.outfitSugerido.abrigo
        ]
        let clothingItems = ids.compactMap { id -> ClothingItem? in
            guard let id else { return nil }
            return items.first { $0.id == id }
        }
        let grouped = Dictionary(grouping: clothingItems, by: \.resolvedThermalLayer)

        return grouped
            .map { LayerGroup(layer: $0.key, outfitItems: $0.value) }
            .sorted { $0.layer.layerNumber > $1.layer.layerNumber }
    }

    private var footwearItem: ClothingItem? {
        guard let id = response.outfitSugerido.calzado else { return nil }
        return items.first { $0.id == id }
    }

    // ── Body ──────────────────────────────────────────────────────────────────

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            contextHeader
            AccentDivider().padding(.horizontal, 20)
            layerStackSection
            if let shoe = footwearItem {
                AccentDivider().padding(.horizontal, 20)
                footwearRow(shoe)
            }
            AccentDivider().padding(.horizontal, 20)
            styleTipSection
        }
        .luxuryGlowCard()
    }

    // ── Context header ────────────────────────────────────────────────────────

    private var contextHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(Color.dsAccentPrimary)
                    .font(.caption)
                    .accessibilityHidden(true)
                Text(response.climaProcesado)
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsTextTertiary)
            }
            Text(response.analisisContexto)
                .font(.dsBody)
                .foregroundStyle(Color.dsTextSecondary)
                .italic()
        }
        .padding(20)
        .accessibilityElement(children: .combine)
    }

    // ── Layer stack ───────────────────────────────────────────────────────────

    private var layerStackSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "square.3.layers.3d")
                    .font(.caption)
                    .foregroundStyle(Color.dsAccentPrimary)
                Text(Strings.outfitLayerComposition)
                    .font(.dsLabel)
                    .foregroundStyle(Color.dsAccentPrimary)
                    .tracking(2)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)

            if layerGroups.isEmpty {
                Text(Strings.outfitNoItems)
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsTextTertiary)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 18)
            } else {
                ForEach(Array(layerGroups.enumerated()), id: \.element.id) { index, group in
                    VStack(spacing: 10) {
                        layerTierView(group)
                        if index < layerGroups.count - 1 {
                            layerConnector
                        }
                    }
                }
                .padding(.bottom, 18)
            }
        }
    }

    private func layerTierView(_ group: LayerGroup) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Layer badge
            HStack(spacing: 6) {
                Text("\(group.layer.layerNumber)")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color.dsBackground)
                    .frame(width: 16, height: 16)
                    .background(Color.dsAccentPrimary)
                    .clipShape(Circle())

                Text("LAYER \(group.layer.layerNumber)  ·  \(group.layer.localizedName.uppercased())")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.dsAccentPrimary)
                    .tracking(1.5)
            }
            .padding(.horizontal, 20)

            // Items row (fills width; 2 items → split equally)
            HStack(spacing: 8) {
                ForEach(group.outfitItems) { item in
                    GarmentTile(item: item)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var layerConnector: some View {
        HStack {
            Spacer().frame(width: 27)  // aligns with badge center
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.dsAccentPrimary.opacity(0.5))
                    .frame(width: 3, height: 3)
                Rectangle()
                    .fill(Color.dsAccentPrimary.opacity(0.2))
                    .frame(width: 0.5, height: 18)
                Circle()
                    .fill(Color.dsAccentPrimary.opacity(0.5))
                    .frame(width: 3, height: 3)
            }
            Spacer()
        }
    }

    // ── Footwear row ──────────────────────────────────────────────────────────

    private func footwearRow(_ item: ClothingItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "shoeprints.fill")
                    .font(.caption)
                    .foregroundStyle(Color.dsAccentPrimary.opacity(0.7))
                Text(Strings.outfitFootwear)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.dsTextTertiary)
                    .tracking(1.5)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)

            HStack(spacing: 8) {
                GarmentTile(item: item)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
    }

    // ── Style tip ─────────────────────────────────────────────────────────────

    private var styleTipSection: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "sparkles")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color.dsAccentPrimary)
                .font(.caption)
                .padding(.top, 1)
            Text(response.consejoEstilo)
                .font(.dsCaption)
                .foregroundStyle(Color.dsTextSecondary)
                .italic()
        }
        .padding(20)
    }
}

// ── GarmentTile ───────────────────────────────────────────────────────────────

private struct GarmentTile: View {
    let item: ClothingItem

    @State private var loadedImage: UIImage?

    var body: some View {
        HStack(spacing: 10) {
            garmentThumbnail
            itemDetails
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.dsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.dsAccentPrimary.opacity(0.12), lineWidth: 0.5)
        )
        .task(id: item.id) {
            guard let url = item.resolvedImageURL else { return }
            loadedImage = await ImageLoader.shared.load(from: url)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.subcategory?.localizedName ?? item.category.localizedName)
    }

    @ViewBuilder
    private var garmentThumbnail: some View {
        Group {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Color.dsCardBackground
                    .overlay(
                        SilhouetteView(category: item.category, size: 38)
                    )
            }
        }
        .frame(width: DSSize.garmentTileWidth, height: DSSize.garmentTileHeight)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private var itemDetails: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(item.category.rawValue.capitalized)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.dsTextPrimary)
                .tracking(0.5)

            HStack(spacing: 4) {
                Circle()
                    .fill(Color(hex: item.primaryColor))
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                Text(item.primaryColor.uppercased())
                    .font(.system(size: 9, weight: .regular, design: .monospaced))
                    .foregroundStyle(Color.dsTextTertiary)
            }

            Text(item.style)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color.dsTextTertiary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.dsBackground)
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

            if !item.tags.isEmpty {
                Text(item.tags.prefix(2).joined(separator: " · "))
                    .font(.system(size: 8))
                    .foregroundStyle(Color.dsTextTertiary.opacity(0.7))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
