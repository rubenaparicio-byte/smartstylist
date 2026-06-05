import Foundation
import CoreLocation

struct WeatherData {
    let temperatureCelsius: Double
    let feelsLikeCelsius: Double
    let rainProbability: Double
    let condition: String
    var displayString: String {
        "\(Int(temperatureCelsius))°C, \(condition)"
    }
}

final class WeatherService {
    private let apiKey = APIKeys.openWeather

    func fetchWeather(for coordinate: CLLocationCoordinate2D) async throws -> WeatherData {
        let lat = coordinate.latitude
        let lon = coordinate.longitude
        let urlString = "https://api.openweathermap.org/data/3.0/onecall"
            + "?lat=\(lat)&lon=\(lon)&exclude=minutely,hourly,daily,alerts"
            + "&units=metric&appid=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw WeatherError.serverError
        }

        return try parseWeatherResponse(data)
    }

    private func parseWeatherResponse(_ data: Data) throws -> WeatherData {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let current = json?["current"] as? [String: Any] else {
            throw WeatherError.parseError
        }

        let temp      = current["temp"]       as? Double ?? 0
        let feelsLike = current["feels_like"] as? Double ?? temp
        let weather   = (current["weather"] as? [[String: Any]])?.first
        let condDesc  = weather?["main"] as? String ?? "Clear"

        let isRainy   = ["Rain", "Drizzle", "Thunderstorm"].contains(condDesc)
        let rainProb  = isRainy ? 0.8 : 0.0

        return WeatherData(
            temperatureCelsius: temp,
            feelsLikeCelsius: feelsLike,
            rainProbability: rainProb,
            condition: condDesc
        )
    }
}

enum WeatherError: LocalizedError {
    case invalidURL, serverError, parseError
    var errorDescription: String? {
        switch self {
        case .invalidURL:   return "Invalid weather URL."
        case .serverError:  return "Weather server error."
        case .parseError:   return "Could not parse weather data."
        }
    }
}
