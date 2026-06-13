import SwiftUI

extension Color {
    // ── Backgrounds ──────────────────────────────────────────
    static let dsBackground  = Color(hex: "#1C1C1E")
    static let dsCardBackground  = Color(hex: "#2C2C2E")
    static let dsSurface    = Color(hex: "#3A3A3C")

    // ── Accents ──────────────────────────────────────────────
    static let dsAccentPrimary = Color(hex: "#D4AF37")
    static let dsAccentSecondary   = Color(hex: "#E9C46A")
    static let dsErrorRed   = Color(hex: "#E63946")

    // ── Text ─────────────────────────────────────────────────
    static let dsTextPrimary   = Color.white
    static let dsTextSecondary = Color.white.opacity(0.6)
    static let dsTextTertiary  = Color.white.opacity(0.35)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
