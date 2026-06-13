import SwiftUI

// ── Display extension (View-layer only) ───────────────────────────────────────

extension StyleEngineError {
    var icon: String {
        switch self {
        case .insufficientWardrobe: return "tshirt"
        case .locationDenied:       return "location.slash"
        case .aiUnavailable:        return "wifi.exclamationmark"
        }
    }

    var localizedTitle: String {
        switch self {
        case .insufficientWardrobe: return String(localized: "error.wardrobe.title")
        case .locationDenied:       return String(localized: "error.location.title")
        case .aiUnavailable:        return String(localized: "error.ai.title")
        }
    }

    var localizedSubtitle: String {
        switch self {
        case .insufficientWardrobe:
            return String(localized: "error.wardrobe.subtitle")
        case .locationDenied:
            return String(localized: "error.location.subtitle")
        case .aiUnavailable(let msg):
            return msg.isEmpty ? String(localized: "error.ai.subtitle") : msg
        }
    }

    var canRetry: Bool {
        switch self {
        case .insufficientWardrobe, .locationDenied: return false
        case .aiUnavailable:                         return true
        }
    }

    var needsSettings: Bool { self == .locationDenied }
}

// ── LuxuryErrorView ───────────────────────────────────────────────────────────

struct LuxuryErrorView: View {
    let error: StyleEngineError
    var onRetry: (() -> Void)?

    var body: some View {
        VStack(spacing: 28) {
            iconBadge
            messageBlock
            if error.canRetry || error.needsSettings { actionBlock }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 60)
        .frame(maxWidth: .infinity)
    }

    // ── Sub-components ────────────────────────────────────────────────────────

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(Color.dsSurface)
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(Color.dsAccentPrimary.opacity(0.22), lineWidth: 0.5)
                )
            Image(systemName: error.icon)
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Color.dsAccentPrimary.opacity(0.7))
        }
        .accessibilityHidden(true)
    }

    private var messageBlock: some View {
        VStack(spacing: 8) {
            Text(error.localizedTitle)
                .font(.dsTitle2)
                .foregroundStyle(Color.dsTextPrimary)
                .tracking(2)
                .multilineTextAlignment(.center)

            Text(error.localizedSubtitle)
                .font(.dsBody)
                .foregroundStyle(Color.dsTextSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var actionBlock: some View {
        VStack(spacing: 10) {
            if error.canRetry, let onRetry {
                Button(action: onRetry) {
                    Text(String(localized: "common.retry"))
                        .font(.dsBodyMedium)
                        .foregroundStyle(Color.dsBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.dsAccentPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: Color.dsAccentPrimary.opacity(0.3), radius: 10, y: 5)
                }
            }

            if error.needsSettings {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    Text(String(localized: "common.open_settings"))
                        .font(.dsBodyMedium)
                        .foregroundStyle(Color.dsAccentPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.dsSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.dsAccentPrimary.opacity(0.3), lineWidth: 0.5)
                        )
                }
            }
        }
    }
}
