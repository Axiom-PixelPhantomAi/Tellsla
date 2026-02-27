import Foundation
import MapKit

nonisolated enum MapType: String, CaseIterable, Sendable {
    case standard = "Standard"
    case satellite = "Satellite"
    case hybrid = "Hybrid"
    case hybridFlyover = "3D Flyover"
    case mutedStandard = "Muted"

    var icon: String {
        switch self {
        case .standard: return "map"
        case .satellite: return "globe.americas"
        case .hybrid: return "map.fill"
        case .hybridFlyover: return "view.3d"
        case .mutedStandard: return "map.circle"
        }
    }
}

nonisolated struct WeatherInfo: Sendable {
    let temperature: Double
    let condition: String
    let conditionIcon: String
    let windSpeed: Double
    let locationName: String
    let humidity: Int
    let hourlyForecast: [HourlyWeather]
}

nonisolated struct HourlyWeather: Identifiable, Sendable {
    let id: String
    let hour: String
    let temp: Double
    let icon: String
}

nonisolated struct ChargingSession: Codable, Identifiable, Sendable {
    let id: String
    let date: Date
    let kWhAdded: Double
    let cost: Double
    let durationMinutes: Int
    let location: String
    let chargerType: ChargerType
    let startBattery: Int
    let endBattery: Int
}

nonisolated enum ChargerType: String, Codable, Sendable {
    case home = "Home"
    case supercharger = "Supercharger"
    case thirdParty = "Third Party"
}

nonisolated struct CrashLogEntry: Codable, Identifiable, Sendable {
    let id: String
    let timestamp: Date
    let level: LogLevel
    let message: String
    let context: String?
}

nonisolated enum LogLevel: String, Codable, Sendable {
    case info, warning, error, critical
}

nonisolated struct RoutineTemplate: Identifiable, Sendable {
    let id: String
    let name: String
    let icon: String
    let description: String
    let category: TemplateCategory
    let triggers: [RoutineTrigger]
    let actions: [RoutineAction]
    let rating: Double
    let installCount: Int
}

nonisolated enum TemplateCategory: String, CaseIterable, Sendable {
    case morning = "Morning"
    case commute = "Commute"
    case weather = "Weather"
    case charging = "Charging"
    case security = "Security"
    case trips = "Trips"
}
