import SwiftUI

/// Premium loading overlay shown during AI outfit generation.
/// Displays an animated multi-ring gold spinner with cycling localized messages.
struct LuxuryLoadingView: View {
    @State private var rotation: Double = 0
    @State private var innerScale: CGFloat = 0.8
    @State private var pulseOpacity: Double = 0.12
    @State private var messageIndex = 0

    // Keys resolved via Localizable.strings at render time.
    private let messages: [LocalizedStringKey] = [
        "loading.analysing_wardrobe",
        "loading.reading_colour",
        "loading.curating_look",
        "loading.almost_ready"
    ]

    var body: some View {
        VStack(spacing: 28) {
            spinner
                .accessibilityHidden(true)
            Text(messages[messageIndex])
                .font(.dsBody)
                .foregroundStyle(Color.dsTextSecondary)
                .multilineTextAlignment(.center)
                .id(messageIndex)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .bottom)),
                    removal:   .opacity
                ))
                .accessibilityAddTraits(.updatesFrequently)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 80)
        .task { await cycleMessages() }
        .onAppear { startAnimations() }
    }

    // ── Spinner ───────────────────────────────────────────────────────────────

    private var spinner: some View {
        ZStack {
            // Outer sweep arc — slow clockwise rotation
            Circle()
                .trim(from: 0, to: 0.72)
                .stroke(
                    AngularGradient(
                        colors: [Color.dsAccentPrimary.opacity(0), Color.dsAccentPrimary],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round)
                )
                .frame(width: 72, height: 72)
                .rotationEffect(.degrees(rotation))

            // Middle ring — static, low-opacity
            Circle()
                .stroke(Color.dsAccentPrimary.opacity(0.15), lineWidth: 0.5)
                .frame(width: 50, height: 50)

            // Inner glow — pulsing
            Circle()
                .fill(Color.dsAccentPrimary.opacity(pulseOpacity))
                .frame(width: 30, height: 30)
                .scaleEffect(innerScale)

            // Centre dot
            Circle()
                .fill(Color.dsAccentPrimary)
                .frame(width: 5, height: 5)
        }
    }

    // ── Animation drivers ─────────────────────────────────────────────────────

    private func startAnimations() {
        withAnimation(.linear(duration: 2.8).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        withAnimation(.easeInOut(duration: 1.3).repeatForever(autoreverses: true)) {
            innerScale    = 1.18
            pulseOpacity  = 0.32
        }
    }

    private func cycleMessages() async {
        for i in 1..<messages.count {
            try? await Task.sleep(for: .seconds(2.2))
            withAnimation(.dsDefault) { messageIndex = i }
        }
    }
}
