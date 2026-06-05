import XCTest
@testable import SmartStylist

final class StyleEngineViewModelTests: XCTestCase {

    // ── CurrentWeatherData ────────────────────────────────────────────────────

    func test_currentWeather_requiresUmbrella_forRain() {
        let raw = WeatherData(temperatureCelsius: 14, feelsLikeCelsius: 12,
                              rainProbability: 0.8, condition: "Rain")
        XCTAssertTrue(CurrentWeatherData(from: raw).requiresUmbrella)
    }

    func test_currentWeather_requiresUmbrella_forDrizzle() {
        let raw = WeatherData(temperatureCelsius: 16, feelsLikeCelsius: 14,
                              rainProbability: 0.5, condition: "Drizzle")
        XCTAssertTrue(CurrentWeatherData(from: raw).requiresUmbrella)
    }

    func test_currentWeather_requiresUmbrella_forThunderstorm() {
        let raw = WeatherData(temperatureCelsius: 10, feelsLikeCelsius: 7,
                              rainProbability: 0.95, condition: "Thunderstorm")
        XCTAssertTrue(CurrentWeatherData(from: raw).requiresUmbrella)
    }

    func test_currentWeather_noUmbrella_forClear() {
        let raw = WeatherData(temperatureCelsius: 23, feelsLikeCelsius: 21,
                              rainProbability: 0, condition: "Clear")
        XCTAssertFalse(CurrentWeatherData(from: raw).requiresUmbrella)
    }

    func test_currentWeather_noUmbrella_forClouds() {
        let raw = WeatherData(temperatureCelsius: 18, feelsLikeCelsius: 16,
                              rainProbability: 0, condition: "Clouds")
        XCTAssertFalse(CurrentWeatherData(from: raw).requiresUmbrella)
    }

    func test_currentWeather_displayString_roundsTemperature() {
        let raw = WeatherData(temperatureCelsius: 21.7, feelsLikeCelsius: 19.2,
                              rainProbability: 0, condition: "Clear")
        XCTAssertEqual(CurrentWeatherData(from: raw).displayString, "21°C, Clear")
    }

    // ── EventContext ──────────────────────────────────────────────────────────

    func test_eventContext_allCasesHaveNonEmptyDresscode() {
        for ctx in EventContext.allCases {
            XCTAssertFalse(ctx.dresscode.isEmpty, "\(ctx.rawValue) has empty dresscode")
        }
    }

    func test_eventContext_allCasesHaveNonEmptyIcon() {
        for ctx in EventContext.allCases {
            XCTAssertFalse(ctx.icon.isEmpty, "\(ctx.rawValue) has empty icon")
        }
    }

    func test_eventContext_allCasesHaveNonEmptyRawValue() {
        for ctx in EventContext.allCases {
            XCTAssertFalse(ctx.rawValue.isEmpty)
        }
    }

    // ── StyleResponse + new CodingKeys ────────────────────────────────────────

    func test_styleResponse_decodesWithIdSuffixKeys() throws {
        let json = """
        {
          "clima_procesado": "20°C, Clear",
          "analisis_contexto": "Perfect spring conditions.",
          "outfit_sugerido": {
            "superior_id": "11111111-1111-1111-1111-111111111111",
            "inferior_id": "22222222-2222-2222-2222-222222222222",
            "calzado_id":  "33333333-3333-3333-3333-333333333333",
            "abrigo_id":   null
          },
          "consejo_estilo": "A relaxed tuck elevates the silhouette."
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(StyleResponse.self, from: json)
        XCTAssertEqual(response.outfitSugerido.allItemIds.count, 3)
        XCTAssertNil(response.outfitSugerido.abrigo)
        XCTAssertEqual(response.climaProcesado, "20°C, Clear")
    }

    func test_styleResponse_allItemIds_excludesNils() throws {
        let suggestion = StyleResponse.OutfitSuggestion(
            superior: UUID(), inferior: UUID(), calzado: nil, abrigo: nil
        )
        XCTAssertEqual(suggestion.allItemIds.count, 2)
    }

    // ── OutfitHistory creation ────────────────────────────────────────────────

    func test_outfitHistory_storesAllIds() {
        let ids = [UUID(), UUID(), UUID()]
        let entry = OutfitHistory(
            clothingItemIds: ids,
            context: "Work Meeting",
            weatherContext: "15°C, Cloudy"
        )
        XCTAssertEqual(entry.clothingItemIds.count, 3)
        XCTAssertEqual(entry.context, "Work Meeting")
        XCTAssertEqual(entry.weatherContext, "15°C, Cloudy")
    }

    func test_outfitHistory_defaultDateIsNow() {
        let before = Date()
        let entry = OutfitHistory(clothingItemIds: [])
        let after = Date()
        XCTAssertGreaterThanOrEqual(entry.date, before)
        XCTAssertLessThanOrEqual(entry.date, after)
    }
}
