import SwiftUI

struct WeatherBadgeView: View {
    let weather: CurrentWeatherData

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: weather.conditionIcon)
                .foregroundStyle(Color.dsAccentGold)
                .font(.title3)

            VStack(alignment: .leading, spacing: 2) {
                Text(weather.displayString)
                    .font(.dsBodyMedium)
                    .foregroundStyle(Color.dsTextPrimary)
                Text(Strings.weatherFeelsLike(Int(weather.feelsLikeCelsius)))
                    .font(.dsCaption)
                    .foregroundStyle(Color.dsTextSecondary)
            }

            Spacer()

            if weather.requiresUmbrella {
                HStack(spacing: 4) {
                    Image(systemName: "umbrella.fill")
                        .foregroundStyle(Color.dsAccentGold)
                    Text(Strings.weatherUmbrella)
                        .font(.dsCaption)
                        .foregroundStyle(Color.dsTextSecondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(14)
        .luxuryCard()
        .animation(.dsDefault, value: weather.requiresUmbrella)
    }
}
