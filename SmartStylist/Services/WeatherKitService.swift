import CoreLocation
import Foundation
import WeatherKit

// WeatherKit.WeatherService is fully qualified throughout this file to avoid
// ambiguity with the project's own WeatherService (OpenWeather) type.

final class WeatherKitService {
    private let service = WeatherKit.WeatherService.shared

    func fetchWeather(for coordinate: CLLocationCoordinate2D) async throws -> WeatherData {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let weather = try await service.weather(for: location)
        let current = weather.currentWeather

        let tempC      = current.temperature.converted(to: .celsius).value
        let feelsLikeC = current.apparentTemperature.converted(to: .celsius).value
        let condition  = Self.conditionString(from: current.condition)
        let rainProb   = ["Rain", "Drizzle", "Thunderstorm"].contains(condition) ? 0.8 : 0.0

        return WeatherData(
            temperatureCelsius: tempC,
            feelsLikeCelsius:   feelsLikeC,
            rainProbability:    rainProb,
            condition:          condition
        )
    }

    // Maps WeatherKit's enum to the condition strings used throughout the app.
    // Matches the subset that CurrentWeatherData.conditionIcon and requiresUmbrella rely on.
    private static func conditionString(from condition: WeatherCondition) -> String {
        switch condition {
        case .blizzard, .blowingSnow, .flurries, .frigid,
             .hail, .heavySnow, .sleet, .snow, .sunFlurries, .wintryMix:
            return "Snow"

        case .drizzle, .freezingDrizzle, .freezingRain:
            return "Drizzle"

        case .heavyRain, .rain, .sunShowers:
            return "Rain"

        case .hurricane, .isolatedThunderstorms, .scatteredThunderstorms,
             .strongStorms, .thunderstorms, .tropicalStorm:
            return "Thunderstorm"

        case .blowingDust, .foggy, .haze, .smoky:
            return "Fog"

        case .cloudy, .mostlyCloudy, .partlyCloudy:
            return "Clouds"

        case .breezy, .clear, .hot, .mostlyClear, .windy:
            return "Clear"

        @unknown default:
            return "Clear"
        }
    }
}
