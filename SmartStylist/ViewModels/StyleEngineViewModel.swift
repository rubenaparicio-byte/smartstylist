import Foundation
import SwiftData
import Observation

// ── StyleEngineError ──────────────────────────────────────────────────────────

enum StyleEngineError: Equatable {
    case insufficientWardrobe
    case locationDenied
    case aiUnavailable(String)

    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.insufficientWardrobe, .insufficientWardrobe): return true
        case (.locationDenied, .locationDenied):             return true
        case (.aiUnavailable(let a), .aiUnavailable(let b)): return a == b
        default:                                             return false
        }
    }
}

// ── EventContext ──────────────────────────────────────────────────────────────

enum EventContext: String, CaseIterable {
    case daily         = "Daily"
    case work          = "Work Meeting"
    case eveningDate   = "Evening Date"
    case gym           = "Gym"
    case casualWeekend = "Casual Weekend"
    case formal        = "Formal Event"

    // rawValue sent to Gemini (English, not localised)
    var dresscode: String {
        switch self {
        case .daily:         return "Smart casual, versatile for any daytime activity"
        case .work:          return "Business casual or formal; polished, refined appearance"
        case .eveningDate:   return "Elevated smart casual; romantic and effortlessly chic"
        case .gym:           return "Athletic performance wear; comfort and full range of motion"
        case .casualWeekend: return "Relaxed casual; effortless and comfortable"
        case .formal:        return "Black tie or formal eveningwear; impeccably tailored"
        }
    }

    var icon: String {
        switch self {
        case .daily:         return "sun.horizon"
        case .work:          return "briefcase"
        case .eveningDate:   return "moon.stars"
        case .gym:           return "figure.run"
        case .casualWeekend: return "leaf"
        case .formal:        return "sparkles"
        }
    }

    // UI-facing label, resolved from Localizable.strings
    var localizedName: String {
        switch self {
        case .daily:         return Strings.eventDaily
        case .work:          return Strings.eventWork
        case .eveningDate:   return Strings.eventEveningDate
        case .gym:           return Strings.eventGym
        case .casualWeekend: return Strings.eventCasualWeekend
        case .formal:        return Strings.eventFormal
        }
    }
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

@MainActor
@Observable
final class StyleEngineViewModel {
    var currentWeather: CurrentWeatherData?
    var suggestion: StyleResponse?
    var isLoading          = false
    var currentError: StyleEngineError?
    var occasion: EventContext = .daily
    var outfitSaved        = false
    var isOfflineSuggestion = false

    private let gemini = GeminiService()
    private let wxSvc  = LocationWeatherService()

    func generateOutfit(profile: UserProfile,
                        activeItems: [ClothingItem],
                        history: [OutfitHistory]) async {
        guard activeItems.count >= 2 else {
            currentError = .insufficientWardrobe
            return
        }

        isLoading           = true
        outfitSaved         = false
        currentError        = nil
        suggestion          = nil
        isOfflineSuggestion = false

        // ── Step 1: Weather (best-effort; LocationError is a hard stop) ────────
        do {
            currentWeather = try await wxSvc.refresh()
        } catch is LocationError {
            isLoading    = false
            currentError = .locationDenied
            return
        } catch {
            // Network/weather unavailable — proceed without weather context.
        }

        // ── Step 2: AI outfit suggestion (offline fallback on any failure) ─────
        do {
            let result = try await gemini.suggestOutfit(
                profileJSON:   encodeProfile(profile),
                weatherJSON:   currentWeather.map { encodeWeather($0) } ?? "{}",
                inventoryJSON: encodeInventory(activeItems),
                historyJSON:   encodeHistory(history14Days(from: history)),
                occasion:      "\(occasion.rawValue) — \(occasion.dresscode)"
            )
            suggestion          = result
            isOfflineSuggestion = false
        } catch {
            if let offline = buildOfflineSuggestion(profile: profile, activeItems: activeItems) {
                suggestion          = offline
                isOfflineSuggestion = true
            } else {
                currentError = .aiUnavailable(error.localizedDescription)
            }
        }

        isLoading = false
    }

    func saveOutfit(to context: ModelContext) {
        guard let s = suggestion, !outfitSaved else { return }
        let ids = s.outfitSugerido.allItemIds
        guard !ids.isEmpty else { return }
        let entry = OutfitHistory(
            clothingItemIds: ids,
            context: occasion.rawValue,
            weatherContext: currentWeather?.displayString ?? ""
        )
        context.insert(entry)
        try? context.save()
        outfitSaved = true
    }

    // ── Offline Fallback ──────────────────────────────────────────────────────
    // Builds a local outfit using colorimetry scoring when Gemini is unavailable.
    // Returns nil if the wardrobe lacks the minimum categories (top + bottom + shoes).

    private func buildOfflineSuggestion(profile: UserProfile,
                                        activeItems: [ClothingItem]) -> StyleResponse? {
        let recommendedHexes = Set(profile.recommendedColorHexes.map { $0.lowercased() })
        let neutralHexes: Set<String> = [
            "#000000", "#ffffff", "#f5f5dc", "#808080",
            "#c0c0c0", "#000080", "#f5f5f5", "#d3d3d3", "#2f4f4f"
        ]

        func score(_ item: ClothingItem) -> Int {
            let hex = item.primaryColor.lowercased()
            if recommendedHexes.contains(hex) { return 2 }
            if neutralHexes.contains(hex)     { return 1 }
            return 0
        }

        let tops    = activeItems.filter { $0.category == .top }
                                 .sorted { score($0) > score($1) }
        let bottoms = activeItems.filter { $0.category == .bottom }
                                 .sorted { score($0) > score($1) }
        let shoes   = activeItems.filter { $0.category == .footwear }
                                 .sorted { score($0) > score($1) }
        let outers  = activeItems.filter { $0.category == .outerwear }
                                 .sorted { score($0) > score($1) }

        guard let top = tops.first, let bottom = bottoms.first, let shoe = shoes.first else {
            return nil
        }

        let season = profile.seasonalColorimetry.isEmpty
            ? "your season"
            : profile.seasonalColorimetry

        return StyleResponse(
            climaProcesado:   "Offline — weather unavailable",
            analisisContexto: "Curated from your \(season) palette without AI",
            outfitSugerido: StyleResponse.OutfitSuggestion(
                superior: top.id,
                inferior: bottom.id,
                calzado:  shoe.id,
                abrigo:   outers.first?.id
            ),
            consejoEstilo: "Trust your \(season) season — your wardrobe knows you."
        )
    }

    // ── Helpers ───────────────────────────────────────────────────────────────

    private func history14Days(from history: [OutfitHistory]) -> [OutfitHistory] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        return history.filter { $0.date >= cutoff }
    }

    private func encodeProfile(_ p: UserProfile) -> String {
        """
        {"bodyType":"\(p.bodyType)","skinTone":"\(p.skinTone)",\
        "eyeColor":"\(p.eyeColor)","hairColor":"\(p.hairColor)",\
        "season":"\(p.seasonalColorimetry)","guidelines":"\(p.styleGuidelines)",\
        "metalPreference":"\(p.metalPreference)"}
        """
    }

    private func encodeWeather(_ w: CurrentWeatherData) -> String {
        """
        {"temp":\(Int(w.temperatureCelsius)),"feelsLike":\(Int(w.feelsLikeCelsius)),\
        "condition":"\(w.condition)","requiresUmbrella":\(w.requiresUmbrella)}
        """
    }

    private func encodeInventory(_ items: [ClothingItem]) -> String {
        let entries = items.map { item in
            let tagsJSON = item.tags.map { "\"\($0)\"" }.joined(separator: ",")
            let subcatField = item.subcategory.map { ",\"subcategory\":\"\($0.rawValue)\"" } ?? ""
            return """
            {"id":"\(item.id.uuidString)","category":"\(item.category.rawValue)"\(subcatField),\
            "thermalLayer":"\(item.resolvedThermalLayer.rawValue)","layerNumber":\(item.resolvedThermalLayer.layerNumber),\
            "primaryColor":"\(item.primaryColor)","pattern":"\(item.pattern)",\
            "style":"\(item.style)","tags":[\(tagsJSON)]}
            """
        }
        return "[\(entries.joined(separator: ","))]"
    }

    private func encodeHistory(_ history: [OutfitHistory]) -> String {
        let entries = history.map { h in
            let ids = h.clothingItemIds.map { "\"\($0.uuidString)\"" }.joined(separator: ",")
            return """
            {"date":"\(h.date.ISO8601Format())","context":"\(h.context)","items":[\(ids)]}
            """
        }
        return "[\(entries.joined(separator: ","))]"
    }
}
