import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class StyleEngineViewModel {
    var currentWeather: WeatherData?
    var suggestion: StyleResponse?
    var isLoading = false
    var errorMessage: String?
    var occasion = "Daily"

    private let gemini   = GeminiService()
    private let weather  = WeatherService()
    private let location = LocationService()

    @MainActor
    func generateOutfit(profile: UserProfile,
                        activeItems: [ClothingItem],
                        history: [OutfitHistory]) async {
        isLoading = true
        errorMessage = nil

        do {
            let coord = try await location.requestCoordinate()
            let wx    = try await weather.fetchWeather(for: coord)
            currentWeather = wx

            let profileJSON   = encodeProfile(profile)
            let weatherJSON   = encodeWeather(wx)
            let inventoryJSON = encodeInventory(activeItems)
            let historyJSON   = encodeHistory(Array(history.filter {
                Calendar.current.dateComponents([.day], from: $0.date, to: Date()).day ?? 999 <= 14
            }))

            let result = try await gemini.suggestOutfit(
                profileJSON: profileJSON,
                weatherJSON: weatherJSON,
                inventoryJSON: inventoryJSON,
                historyJSON: historyJSON,
                occasion: occasion
            )
            suggestion = result

        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    private func encodeProfile(_ p: UserProfile) -> String {
        """
        {"bodyType":"\(p.bodyType)","skinTone":"\(p.skinTone)",
         "eyeColor":"\(p.eyeColor)","hairColor":"\(p.hairColor)",
         "season":"\(p.seasonalColorimetry)","guidelines":"\(p.styleGuidelines)"}
        """
    }

    private func encodeWeather(_ w: WeatherData) -> String {
        """
        {"temp":\(w.temperatureCelsius),"feelsLike":\(w.feelsLikeCelsius),
         "condition":"\(w.condition)","rainProbability":\(w.rainProbability)}
        """
    }

    private func encodeInventory(_ items: [ClothingItem]) -> String {
        let entries = items.map { item in
            """
            {"id":"\(item.id.uuidString)","category":"\(item.category.rawValue)",
             "primaryColor":"\(item.primaryColor)","pattern":"\(item.pattern)",
             "style":"\(item.style)","tags":\(item.tags.map { "\"\($0)\"" })}
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
