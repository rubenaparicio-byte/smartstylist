import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.modelContext) private var ctx
    @Environment(\.dismiss) private var dismiss

    @State private var category: ClothingCategory = .top
    @State private var style = ""
    @State private var primaryColor = "#000000"
    @State private var tags = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.dsDeepSlate.ignoresSafeArea()
                Form {
                    Picker("Category", selection: $category) {
                        ForEach(ClothingCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue.capitalized).tag(cat)
                        }
                    }
                    TextField("Style (Casual, Formal…)", text: $style)
                    TextField("Primary colour hex", text: $primaryColor)
                    TextField("Tags (comma separated)", text: $tags)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Piece")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let tagList = tags.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let item = ClothingItem(category: category,
                                primaryColor: primaryColor,
                                style: style.isEmpty ? "Casual" : style,
                                tags: tagList)
        ctx.insert(item)
        try? ctx.save()
        dismiss()
    }
}
