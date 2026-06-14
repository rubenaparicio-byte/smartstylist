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
    private var generationTask: Task<Void, Never>?

    private static let suggestionCacheKey = "ss_lastSuggestion"

    init() {
        // Restore last cached suggestion so the tab isn't blank on re-open
        if let data = UserDefaults.standard.data(forKey: Self.suggestionCacheKey),
           let cached = try? JSONDecoder().decode(StyleResponse.self, from: data) {
            suggestion = cached
        }
    }

    func cancelGeneration() {
        generationTask?.cancel()
        generationTask = nil
        isLoading = false
    }

    func generateOutfit(profile: UserProfile,
                        activeItems: [ClothingItem],
                        history: [OutfitHistory]) async {
        guard activeItems.count >= 2 else {
            currentError = .insufficientWardrobe
            return
        }
        guard !Task.isCancelled else { return }

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
                inventoryJSON: encodeInventory(filteredWardrobe(activeItems, profile: profile, weather: currentWeather, occasion: occasion)),
                historyJSON:   encodeHistory(history14Days(from: history)),
                occasion:      "\(occasion.rawValue) — \(occasion.dresscode)"
            )
            suggestion          = result
            isOfflineSuggestion = false
            persistSuggestion(result)
        } catch {
            if let offline = buildOfflineSuggestion(profile: profile, activeItems: activeItems) {
                suggestion          = offline
                isOfflineSuggestion = true
                persistSuggestion(offline)
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
        do {
            try context.save()
            outfitSaved = true
        } catch {
            Task { await DebugLogger.shared.log("saveOutfit failed: \(error.localizedDescription)") }
        }
    }

    private func persistSuggestion(_ response: StyleResponse) {
        if let data = try? JSONEncoder().encode(response) {
            UserDefaults.standard.set(data, forKey: Self.suggestionCacheKey)
        }
    }

    // ── Offline Fallback ──────────────────────────────────────────────────────
    // Builds a local outfit using colorimetry scoring when Gemini is unavailable.
    // Returns nil if the wardrobe lacks the minimum categories (top + bottom + shoes).

    private static let neutralHexes: Set<String> = [
        "#000000", "#ffffff", "#f5f5dc", "#808080",
        "#c0c0c0", "#000080", "#f5f5f5", "#d3d3d3", "#2f4f4f"
    ]

    private func buildOfflineSuggestion(profile: UserProfile,
                                        activeItems: [ClothingItem]) -> StyleResponse? {
        let recommendedHexes = Set(profile.recommendedColorHexes.map { $0.lowercased() })

        func score(_ item: ClothingItem) -> Int {
            let hex = item.primaryColor.lowercased()
            if recommendedHexes.contains(hex)     { return 2 }
            if Self.neutralHexes.contains(hex)     { return 1 }
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

    // Reduces the wardrobe to a relevance-ranked subset before LLM encoding.
    // Filters by occasion style and temperature, then caps each category at 8 items
    // ordered by colorimetry score so the LLM sees the best candidates first.
    private func filteredWardrobe(_ items: [ClothingItem],
                                   profile: UserProfile,
                                   weather: CurrentWeatherData?,
                                   occasion: EventContext) -> [ClothingItem] {
        let recommendedHexes = Set(profile.recommendedColorHexes.map { $0.lowercased() })

        func colorScore(_ item: ClothingItem) -> Int {
            let hex = item.primaryColor.lowercased()
            if recommendedHexes.contains(hex)  { return 2 }
            if Self.neutralHexes.contains(hex) { return 1 }
            return 0
        }

        let allowedStyles: Set<String>? = {
            switch occasion {
            case .gym:         return ["Athletic"]
            case .formal:      return ["Formal", "Smart Casual", "Evening"]
            case .eveningDate: return ["Evening", "Smart Casual", "Formal"]
            default:           return nil
            }
        }()

        let temp = weather?.temperatureCelsius ?? 15
        let formalOccasion = occasion == .formal || occasion == .eveningDate || occasion == .work
        let skipOuterwear  = temp > 24 && !formalOccasion
        // Formal occasions may still need a blazer in heat — allow 3 outer items max.
        let outerCap       = temp > 24 && formalOccasion ? 3 : 8

        var result: [ClothingItem] = []
        for category in ClothingCategory.allCases {
            if category == .outerwear && skipOuterwear { continue }
            let cap = category == .outerwear ? outerCap : 8

            var pool = items.filter { $0.category == category }
            if let allowed = allowedStyles {
                let filtered = pool.filter { allowed.contains($0.style) }
                if !filtered.isEmpty { pool = filtered }
            }

            result.append(contentsOf: pool.sorted { colorScore($0) > colorScore($1) }.prefix(cap))
        }
        return result
    }

    private func encodeProfile(_ p: UserProfile) -> String {
        let genderField   = p.gender.map { ",\"gender\":\"\($0)\"" } ?? ""
        let storesField   = p.preferredStores.isEmpty ? "" : ",\"preferredStores\":[\(p.preferredStores.map { "\"\($0)\"" }.joined(separator: ","))]"
        let accField      = p.accessoryStyle.isEmpty  ? "" : ",\"accessoryStyle\":[\(p.accessoryStyle.map  { "\"\($0)\"" }.joined(separator: ","))]"
        return """
        {"bodyType":"\(p.bodyType)","skinTone":"\(p.skinTone)",\
        "eyeColor":"\(p.eyeColor)","hairColor":"\(p.hairColor)",\
        "season":"\(p.seasonalColorimetry)","guidelines":"\(p.styleGuidelines)",\
        "metalPreference":"\(p.metalPreference)"\(genderField)\(storesField)\(accField)}
        """
    }

    private func encodeWeather(_ w: CurrentWeatherData) -> String {
        """
        {"temp":\(Int(w.temperatureCelsius)),"feelsLike":\(Int(w.feelsLikeCelsius)),\
        "condition":"\(w.condition)","requiresUmbrella":\(w.requiresUmbrella)}
        """
    }

    // ── Codable payload structs ───────────────────────────────────────────────

    // Short keys reduce per-item token cost (~40% savings over verbose names).
    private struct InventoryItem: Encodable {
        let id: String
        let cat: String    // category
        let sub: String?   // subcategory
        let layer: Int     // thermal layer number (1=base…4=outer)
        let color: String  // primaryColor hex
        let pat: String    // pattern
        let sty: String    // style
        let tags: [String]
    }

    // Compressed history: only the two constraints the LLM needs.
    private struct CompressedHistory: Encodable {
        let rested: [String]  // UUIDs worn ≥3 times in 14 days — must not use today
        let recent: [String]  // UUIDs from the most recent outfit — must differ by ≥2 pieces
    }

    private func encodeInventory(_ items: [ClothingItem]) -> String {
        let payload = items.map { item in
            InventoryItem(
                id:    item.id.uuidString,
                cat:   item.category.rawValue,
                sub:   item.subcategory?.rawValue,
                layer: item.resolvedThermalLayer.layerNumber,
                color: item.primaryColor,
                pat:   item.pattern,
                sty:   item.style,
                tags:  item.tags
            )
        }
        let encoder = JSONEncoder()
        return (try? encoder.encode(payload)).flatMap { String(data: $0, encoding: .utf8) } ?? "[]"
    }

    private func encodeHistory(_ history: [OutfitHistory]) -> String {
        var freq: [UUID: Int] = [:]
        for outfit in history {
            for id in outfit.clothingItemIds { freq[id, default: 0] += 1 }
        }
        let rested = freq.filter { $0.value >= 3 }.map { $0.key.uuidString }
        let recent = history.sorted { $0.date > $1.date }.first?.clothingItemIds.map(\.uuidString) ?? []
        let payload = CompressedHistory(rested: rested, recent: recent)
        return (try? JSONEncoder().encode(payload)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
    }
}
