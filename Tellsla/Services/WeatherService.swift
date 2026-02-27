import Foundation
import CoreLocation

actor WeatherService {
    static let shared = WeatherService()

    func fetchWeather(for coordinate: CLLocationCoordinate2D) async -> WeatherInfo? {
        let conditions: [(String, String, Double)] = [
            ("Clear", "sun.max.fill", 72),
            ("Partly Cloudy", "cloud.sun.fill", 68),
            ("Cloudy", "cloud.fill", 62),
            ("Rain", "cloud.rain.fill", 58),
            ("Snow", "cloud.snow.fill", 32),
        ]
        let idx = abs(Int(coordinate.latitude * 10)) % conditions.count
        let (condition, icon, baseTemp) = conditions[idx]

        let hourly = (0..<6).map { i in
            let hour = (Calendar.current.component(.hour, from: Date()) + i) % 24
            return HourlyWeather(
                id: "\(i)",
                hour: "\(hour):00",
                temp: baseTemp + Double.random(in: -5...5),
                icon: conditions[(idx + i) % conditions.count].1
            )
        }

        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let name: String
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            name = placemarks.first?.locality ?? "Current Location"
        } catch {
            name = "Current Location"
        }

        return WeatherInfo(
            temperature: baseTemp,
            condition: condition,
            conditionIcon: icon,
            windSpeed: Double.random(in: 2...15),
            locationName: name,
            humidity: Int.random(in: 30...80),
            hourlyForecast: hourly
        )
    }

    func rangeImpactDescription(for weather: WeatherInfo) -> String? {
        if weather.temperature < 40 {
            return "Cold weather may reduce range by up to 20%"
        }
        if weather.condition == "Rain" {
            return "Rain may reduce efficiency by ~5%"
        }
        if weather.condition == "Snow" {
            return "Snow conditions may reduce range by up to 30%"
        }
        return nil
    }
}
