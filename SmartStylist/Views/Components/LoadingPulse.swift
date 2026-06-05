import SwiftUI

struct LoadingPulse: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.4

    var body: some View {
        Circle()
            .fill(Color.dsAccentGold)
            .frame(width: 10, height: 10)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    scale = 1.2
                    opacity = 1.0
                }
            }
    }
}
