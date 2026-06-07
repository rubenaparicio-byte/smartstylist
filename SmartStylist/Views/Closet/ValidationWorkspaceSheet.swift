import SwiftUI

struct ValidationWorkspaceSheet: View {
    let prediction: GarmentPrediction
    let imageData: Data?
    var onSaved: () -> Void

    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var category: ClothingCategory
    @State private var thermalLayer: ThermalLayer
    @State private var primaryColor: String
    @State private var pattern: String
    @State private var style: String
    @State private var tagsText: String
    @State private var isSaving = false

    private let segService = GarmentSegmentationService()
    private let patternOptions = ["Solid", "Stripes", "Checks", "Floral", "Abstract", "Animal Print"]
    private let styleOptions   = ["Casual", "Formal", "Smart Casual", "Athletic", "Evening"]

    init(prediction: GarmentPrediction, imageData: Data? = nil, onSaved: @escaping () -> Void = {}) {
        self.prediction = prediction
        self.imageData  = imageData
        self.onSaved    = onSaved
        let detectedCategory = ClothingCategory(rawValue: prediction.category) ?? .top
        self._category     = State(initialValue: detectedCategory)
        self._thermalLayer = State(initialValue: detectedCategory.defaultThermalLayer)
        self._primaryColor = State(initialValue: prediction.primaryColor)
        self._pattern      = State(initialValue: prediction.pattern)
        self._style        = State(initialValue: prediction.style)
        self._tagsText     = State(initialValue: prediction.tags.joined(separator: ", "))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsDeepSlate.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 24) {
                        imagePreview
                        GoldDivider()
                        header
                        fieldsCard
                        tagsCard
                        confirmButton
                    }
                    .padding(20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("VALIDATE PIECE")
                        .font(.dsLabel)
                        .foregroundStyle(Color.dsAccentGold)
                        .tracking(2)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.dsTextSecondary)
                        .disabled(isSaving)
                }
            }
            .toolbarBackground(Material.ultraThinMaterial, for: .navigationBar)
        }
    }

    // ── Subviews ──────────────────────────────────────────────────────────────

    @ViewBuilder
    private var imagePreview: some View {
        if let data = imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.dsAccentGold.opacity(0.2), lineWidth: 0.5)
                )
        } else {
            SilhouetteView(category: category, size: 120)
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .background(Color.dsCardSlate)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("AI ANALYSIS — REVIEW & CONFIRM")
                .font(.dsLabel)
                .foregroundStyle(Color.dsTextSecondary)
                .tracking(1.5)
            Text("Adjust any detail before adding to your wardrobe.")
                .font(.dsBody)
                .foregroundStyle(Color.dsTextTertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var fieldsCard: some View {
        LuxuryCard {
            VStack(spacing: 0) {
                pickerRow("Category") {
                    Picker("", selection: $category) {
                        ForEach(ClothingCategory.allCases, id: \.self) { c in
                            Text(c.rawValue.capitalized).tag(c)
                        }
                    }
                    .tint(Color.dsAccentGold)
                    .onChange(of: category) { _, newCat in
                        thermalLayer = newCat.defaultThermalLayer
                    }
                }
                cardDivider
                pickerRow("Layer") {
                    Picker("", selection: $thermalLayer) {
                        ForEach(ThermalLayer.allCases, id: \.self) { layer in
                            Text("L\(layer.layerNumber) \(layer.displayName)").tag(layer)
                        }
                    }
                    .tint(Color.dsAccentGold)
                }
                cardDivider
                pickerRow("Pattern") {
                    Picker("", selection: $pattern) {
                        ForEach(patternOptions, id: \.self) { Text($0).tag($0) }
                    }
                    .tint(Color.dsAccentGold)
                }
                cardDivider
                pickerRow("Style") {
                    Picker("", selection: $style) {
                        ForEach(styleOptions, id: \.self) { Text($0).tag($0) }
                    }
                    .tint(Color.dsAccentGold)
                }
                cardDivider
                HStack {
                    Text("Colour")
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsTextTertiary)
                    Spacer()
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color(hex: primaryColor))
                            .frame(width: 20, height: 20)
                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 0.5))
                        TextField("#000000", text: $primaryColor)
                            .font(.dsBody)
                            .foregroundStyle(Color.dsTextPrimary)
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .frame(width: 90)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
        }
    }

    private var tagsCard: some View {
        LuxuryCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tags / Occasions")
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsTextTertiary)
                TextField("work, weekend, date night…", text: $tagsText, axis: .vertical)
                    .font(.dsBody)
                    .foregroundStyle(Color.dsTextPrimary)
            }
            .padding(16)
        }
    }

    private var confirmButton: some View {
        Button {
            isSaving = true
            Task { await confirm() }
        } label: {
            Group {
                if isSaving {
                    ProgressView().tint(Color.dsDeepSlate)
                } else {
                    Text("Confirm & Add to Wardrobe")
                        .font(.dsBodyMedium)
                }
            }
            .foregroundStyle(Color.dsDeepSlate)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.dsAccentGold)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .shadow(color: Color.dsAccentGold.opacity(0.3), radius: 12, y: 6)
        }
        .disabled(isSaving)
    }

    private var cardDivider: some View {
        Divider()
            .background(Color.dsSurface)
            .padding(.horizontal, 16)
    }

    private func pickerRow<Content: View>(_ label: String,
                                          @ViewBuilder content: () -> Content) -> some View {
        HStack {
            Text(label)
                .font(.dsCaption)
                .foregroundStyle(Color.dsTextTertiary)
            Spacer()
            content()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
    }

    // ── Save ──────────────────────────────────────────────────────────────────

    @MainActor
    private func confirm() async {
        let id = UUID()
        var path: String? = nil
        if let data = imageData {
            path = try? await segService.saveToDocuments(data, for: id)
        }
        let tagList = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let item = ClothingItem(
            id: id,
            imagePath: path,
            category: category,
            thermalLayer: thermalLayer,
            primaryColor: primaryColor,
            pattern: pattern,
            style: style.isEmpty ? "Casual" : style,
            tags: tagList,
            status: .active
        )
        ctx.insert(item)
        try? ctx.save()
        onSaved()
        dismiss()
    }
}
