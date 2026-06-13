import SwiftUI

struct LuxuryCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .luxuryCard(cornerRadius: cornerRadius)
    }
}

#Preview {
    LuxuryCard {
        Text("Preview")
            .foregroundStyle(Color.dsTextPrimary)
            .padding()
    }
    .padding()
    .background(Color.dsBackground)
}
