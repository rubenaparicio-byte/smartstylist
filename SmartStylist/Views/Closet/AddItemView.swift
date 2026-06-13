import PhotosUI
import SwiftUI

struct AddItemView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var category: ClothingCategory = .top
    @State private var subcategory: ClothingSubcategory? = nil
    @State private var thermalLayer: ThermalLayer = .inner
    @State private var style = ""
    @State private var primaryColor = "#000000"
    @State private var pattern = "Solid"
    @State private var tags = ""

    @State private var selectedPhoto: PhotosPickerItem?
    @State private var rawCameraData: Data?
    @State private var imageData: Data?
    @State private var isSegmenting = false
    @State private var segmentError: String?
    @State private var showCamera = false
    @State private var isAnalysing = false
    @State private var aiError: String?
    @State private var pendingPrediction: GarmentPrediction?
    @State private var showValidation = false

    private let gemini = GeminiService()
    private let segService = GarmentSegmentationService()

    private let patternOptions = ["Solid", "Stripes", "Checks", "Floral", "Abstract", "Animal Print"]
    private let styleOptions   = ["Casual", "Formal", "Smart Casual", "Athletic", "Evening"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsBackground.ignoresSafeArea()
                Form {
                    Section {
                        photoScanSection
                    } header: {
                        Text(Strings.addSectionPhoto)
                            .font(.dsLabel).foregroundStyle(Color.dsAccentPrimary).tracking(1.5)
                    }

                    Section {
                        Picker(Strings.addPickerCategory, selection: $category) {
                            ForEach(ClothingCategory.allCases, id: \.self) { c in
                                Text(c.localizedName).tag(c)
                            }
                        }
                        .onChange(of: category) { _, newCat in
                            subcategory = nil
                            thermalLayer = newCat.defaultThermalLayer
                        }

                        Picker(Strings.addPickerSubcategory, selection: $subcategory) {
                            Text("—").tag(ClothingSubcategory?.none)
                            ForEach(category.subcategories, id: \.self) { sub in
                                Text(sub.localizedName).tag(ClothingSubcategory?.some(sub))
                            }
                        }

                        Picker(Strings.addPickerLayer, selection: $thermalLayer) {
                            ForEach(ThermalLayer.allCases, id: \.self) { layer in
                                Label(
                                    "Layer \(layer.layerNumber) — \(layer.localizedName)",
                                    systemImage: layer.icon
                                ).tag(layer)
                            }
                        }

                        Picker(Strings.validatePickerStyle, selection: $style) {
                            ForEach(styleOptions, id: \.self) { s in
                                Text(s.localizedStyleName).tag(s)
                            }
                        }
                        .onAppear { if style.isEmpty { style = "Casual" } }

                        Picker(Strings.validatePickerPattern, selection: $pattern) {
                            ForEach(patternOptions, id: \.self) { p in
                                Text(p.localizedPatternName).tag(p)
                            }
                        }

                        TextField(Strings.addFieldColour, text: $primaryColor)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)

                        TextField(Strings.addFieldTags, text: $tags)
                    } header: {
                        Text(Strings.addSectionDetails)
                            .font(.dsLabel).foregroundStyle(Color.dsAccentPrimary).tracking(1.5)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(Strings.addNavTitle)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Strings.commonSave) { Task { await saveManual() } }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(Strings.commonCancel) { dismiss() }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker(imageData: $rawCameraData)
                    .ignoresSafeArea()
            }
            .onChange(of: rawCameraData) { _, data in
                guard let data else { return }
                Task { await processCapture(data) }
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
        HStack {
            Spacer()
            photoThumbnail
            Spacer()
        }
        .listRowBackground(Color.clear)
        .padding(.vertical, 4)

        HStack(spacing: 12) {
            Button {
                showCamera = true
            } label: {
                sourceButtonLabel(icon: "camera.fill", title: Strings.addButtonCamera)
            }
            .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                sourceButtonLabel(icon: "photo.on.rectangle", title: Strings.addButtonGallery)
            }
            .onChange(of: selectedPhoto) { _, item in
                Task {
                    if let data = try? await item?.loadTransferable(type: Data.self) {
                        await processCapture(data)
                    }
                }
            }
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

        if let err = segmentError {
            Text(err)
                .font(.dsCaption)
                .foregroundStyle(Color.dsErrorRed)
        }

        if imageData != nil {
            Button {
                Task { await analyseWithAI() }
            } label: {
                HStack(spacing: 8) {
                    if isAnalysing {
                        ProgressView().tint(Color.dsBackground).scaleEffect(0.8)
                    } else {
                        Image(systemName: "wand.and.stars")
                    }
                    Text(isAnalysing ? Strings.addButtonAnalysing : Strings.addButtonAnalyse)
                        .font(.dsBodyMedium)
                }
                .foregroundStyle(Color.dsBackground)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.dsAccentPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(isAnalysing || isSegmenting)
        }

        if let err = aiError {
            Text(err)
                .font(.dsCaption)
                .foregroundStyle(Color.dsErrorRed)
        }
    }

    @ViewBuilder
    private var photoThumbnail: some View {
        if isSegmenting {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.dsSurface)
                .frame(width: 96, height: 96)
                .overlay(
                    VStack(spacing: 6) {
                        ProgressView().tint(Color.dsAccentPrimary)
                        Text(Strings.addLabelSegmenting)
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color.dsTextTertiary)
                    }
                )
        } else if let data = imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 96, height: 96)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.dsAccentPrimary.opacity(0.3), lineWidth: 0.5)
                )
        } else {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.dsSurface)
                .frame(width: 96, height: 96)
                .overlay(
                    Image(systemName: "camera.fill")
                        .font(.system(size: 28, weight: .thin))
                        .foregroundStyle(Color.dsTextTertiary)
                )
        }
    }

    private func sourceButtonLabel(icon: String, title: String) -> some View {
        Label(title, systemImage: icon)
            .font(.dsBodyMedium)
            .foregroundStyle(Color.dsTextPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color.dsSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.dsAccentPrimary.opacity(0.25), lineWidth: 0.5)
            )
    }

    // ── Actions ───────────────────────────────────────────────────────────────

    @MainActor
    private func processCapture(_ raw: Data) async {
        guard let img = UIImage(data: raw) else { return }
        isSegmenting = true
        segmentError = nil
        do {
            imageData = try await segService.segment(img)
        } catch {
            segmentError = error.localizedDescription
            imageData = raw
        }
        isSegmenting = false
    }

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

    @MainActor
    private func saveManual() async {
        let id = UUID()
        var path: String? = nil
        if let data = imageData {
            path = try? await segService.saveToDocuments(data, for: id)
        }
        let tagList = tags.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let item = ClothingItem(
            id: id,
            imagePath: path,
            category: category,
            subcategory: subcategory,
            thermalLayer: thermalLayer,
            primaryColor: primaryColor.isEmpty ? "#000000" : primaryColor,
            pattern: pattern,
            style: style.isEmpty ? "Casual" : style,
            tags: tagList
        )
        ctx.insert(item)
        try? ctx.save()
        dismiss()
    }
}
