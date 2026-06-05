import PhotosUI
import SwiftUI

struct AddItemView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var category: ClothingCategory = .top
    @State private var style = ""
    @State private var primaryColor = "#000000"
    @State private var pattern = "Solid"
    @State private var tags = ""

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var isAnalysing = false
    @State private var aiError: String?
    @State private var pendingPrediction: GarmentPrediction?
    @State private var showValidation = false

    private let gemini = GeminiService()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsDeepSlate.ignoresSafeArea()
                Form {
                    Section {
                        photoScanSection
                    } header: {
                        Text("PHOTO SCAN")
                            .font(.dsLabel).foregroundStyle(Color.dsAccentGold).tracking(1.5)
                    }

                    Section {
                        Picker("Category", selection: $category) {
                            ForEach(ClothingCategory.allCases, id: \.self) { c in
                                Text(c.rawValue.capitalized).tag(c)
                            }
                        }
                        TextField("Style (Casual, Formal…)", text: $style)
                        TextField("Colour hex (#000000)", text: $primaryColor)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                        TextField("Pattern (Solid, Stripes…)", text: $pattern)
                        TextField("Tags (comma separated)", text: $tags)
                    } header: {
                        Text("MANUAL DETAILS")
                            .font(.dsLabel).foregroundStyle(Color.dsAccentGold).tracking(1.5)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Piece")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveManual() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showValidation) {
                if let prediction = pendingPrediction {
                    ValidationWorkspaceSheet(
                        prediction: prediction,
                        imageData: imageData,
                        onSaved: { dismiss() }
                    )
                }
            }
        }
    }

    // ── Photo scan section ────────────────────────────────────────────────────

    @ViewBuilder
    private var photoScanSection: some View {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
            HStack(spacing: 14) {
                photoThumbnail
                VStack(alignment: .leading, spacing: 2) {
                    Text(imageData == nil ? "Select a Photo" : "Photo Selected")
                        .font(.dsBodyMedium)
                        .foregroundStyle(Color.dsTextPrimary)
                    Text("From your library")
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsTextTertiary)
                }
                Spacer()
            }
        }
        .onChange(of: selectedPhoto) { _, item in
            Task { imageData = try? await item?.loadTransferable(type: Data.self) }
        }

        if imageData != nil {
            Button {
                Task { await analyseWithAI() }
            } label: {
                HStack(spacing: 8) {
                    if isAnalysing {
                        ProgressView().tint(Color.dsDeepSlate).scaleEffect(0.8)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isAnalysing ? "Analysing…" : "Analyse with AI")
                        .font(.dsBodyMedium)
                }
                .foregroundStyle(Color.dsDeepSlate)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.dsAccentGold)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(isAnalysing)
        }

        if let err = aiError {
            Text(err)
                .font(.dsCaption)
                .foregroundStyle(Color.dsErrorRed)
        }
    }

    @ViewBuilder
    private var photoThumbnail: some View {
        if let data = imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.dsSurface)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "camera.fill")
                        .foregroundStyle(Color.dsTextTertiary)
                )
        }
    }

    // ── Actions ───────────────────────────────────────────────────────────────

    @MainActor
    private func analyseWithAI() async {
        guard let data = imageData else { return }
        isAnalysing = true
        aiError = nil
        do {
            pendingPrediction = try await gemini.analyseClothingItem(imageData: data)
            showValidation = true
        } catch {
            aiError = "AI analysis failed — add details manually."
        }
        isAnalysing = false
    }

    private func saveManual() {
        let tagList = tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let item = ClothingItem(
            category: category,
            primaryColor: primaryColor.isEmpty ? "#000000" : primaryColor,
            pattern: pattern.isEmpty ? "Solid" : pattern,
            style: style.isEmpty ? "Casual" : style,
            tags: tagList
        )
        ctx.insert(item)
        try? ctx.save()
        dismiss()
    }
}
