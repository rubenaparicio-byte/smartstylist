import CoreLocation
import Foundation

// ── CurrentWeatherData ────────────────────────────────────────────────────────

struct CurrentWeatherData {
    let temperatureCelsius: Double
    let feelsLikeCelsius: Double
    let condition: String
    let requiresUmbrella: Bool

    init(from weather: WeatherData) {
        self.temperatureCelsius = weather.temperatureCelsius
        self.feelsLikeCelsius   = weather.feelsLikeCelsius
        self.condition          = weather.condition
        self.requiresUmbrella   = ["Rain", "Drizzle", "Thunderstorm"].contains(weather.condition)
    }

    var displayString: String { "\(Int(temperatureCelsius))°C, \(condition)" }

    var conditionIcon: String {
        let c = condition.lowercased()
        if c.contains("rain")      { return "cloud.rain" }
        if c.contains("drizzle")   { return "cloud.drizzle" }
        if c.contains("thunder")   { return "cloud.bolt" }
        if c.contains("snow")      { return "snow" }
        if c.contains("fog") || c.contains("mist") { return "cloud.fog" }
        if c.contains("cloud")     { return "cloud" }
        return "sun.max"
    }
}

// ── LocationWeatherService ────────────────────────────────────────────────────

@MainActor
final class LocationWeatherService {
    private let location   = LocationService()
    private let weatherKit = WeatherKitService()   // primary — Apple WeatherKit
    private let weather    = WeatherService()       // fallback — OpenWeather

    func refresh() async throws -> CurrentWeatherData {
        let coord = try await location.requestCoordinate()

        do {
            let raw = try await weatherKit.fetchWeather(for: coord)
            return CurrentWeatherData(from: raw)
        } catch {
            // WeatherKit fails in Simulator and on devices without the entitlement provisioned.
            // Fall back to OpenWeather silently so the rest of the flow is unaffected.
            DebugLogger.shared.log("WeatherKit unavailable (\(error.localizedDescription)) — using OpenWeather")
            let raw = try await weather.fetchWeather(for: coord)
            return CurrentWeatherData(from: raw)
        }
    }
}
