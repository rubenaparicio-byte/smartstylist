import Foundation
import SwiftData
import Observation

// ── EventContext ──────────────────────────────────────────────────────────────

enum EventContext: String, CaseIterable {
    case daily         = "Daily"
    case work          = "Work Meeting"
    case eveningDate   = "Evening Date"
    case gym           = "Gym"
    case casualWeekend = "Casual Weekend"
    case formal        = "Formal Event"

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
}

// ── ViewModel ─────────────────────────────────────────────────────────────────

@MainActor
@Observable
final class StyleEngineViewModel {
    var currentWeather: CurrentWeatherData?
    var suggestion: StyleResponse?
    var isLoading = false
    var errorMessage: String?
    var occasion: EventContext = .daily
    var outfitSaved = false

    private let gemini = GeminiService()
    private let wxSvc  = LocationWeatherService()

    func generateOutfit(profile: UserProfile,
                        activeItems: [ClothingItem],
                        history: [OutfitHistory]) async {
        guard activeItems.count >= 2 else {
            errorMessage = "Add at least 2 active pieces to your wardrobe before generating a suggestion."
            return
        }

        isLoading = true
        outfitSaved = false
        errorMessage = nil

        do {
            let wx = try await wxSvc.refresh()
            currentWeather = wx

            let result = try await gemini.suggestOutfit(
                profileJSON:   encodeProfile(profile),
                weatherJSON:   encodeWeather(wx),
                inventoryJSON: encodeInventory(activeItems),
                historyJSON:   encodeHistory(history14Days(from: history)),
                occasion:      "\(occasion.rawValue) — \(occasion.dresscode)"
            )
            suggestion = result
        } catch {
            errorMessage = error.localizedDescription
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
            return """
            {"id":"\(item.id.uuidString)","category":"\(item.category.rawValue)",\
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
