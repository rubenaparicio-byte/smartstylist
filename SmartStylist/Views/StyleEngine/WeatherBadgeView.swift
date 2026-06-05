import SwiftUI

struct WeatherBadgeView: View {
    let weather: WeatherData

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: weatherIcon(for: weather.condition))
                .foregroundStyle(Color.dsAccentGold)
            VStack(alignment: .leading, spacing: 2) {
                Text(weather.displayString)
                    .font(.dsBodyMedium)
                    .foregroundStyle(Color.dsTextPrimary)
                Text("Feels like \(Int(weather.feelsLikeCelsius))°C")
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsTextSecondary)
            }
            Spacer()
        }
        .padding(14)
        .luxuryCard()
    }

    private func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case let c where c.contains("rain"):    return "cloud.rain"
        case let c where c.contains("cloud"):   return "cloud"
        case let c where c.contains("snow"):    return "snow"
        case let c where c.contains("thunder"): return "cloud.bolt"
        default:                                 return "sun.max"
        }
    }
}
