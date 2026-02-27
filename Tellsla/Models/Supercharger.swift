import Foundation
import CoreLocation

nonisolated struct Supercharger: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
    var totalStalls: Int
    var availableStalls: Int
    var maxPowerKW: Int
    var pricePerKWh: Double?
    var amenities: [ChargerAmenity]
    var status: ChargerStatus
    var distanceMiles: Double?
    var estimatedWaitMinutes: Int?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var availabilityPercent: Double {
        guard totalStalls > 0 else { return 0 }
        return Double(availableStalls) / Double(totalStalls)
    }

    var availabilityColor: String {
        if availabilityPercent > 0.5 { return "green" }
        if availabilityPercent > 0.2 { return "yellow" }
        return "red"
    }
}

nonisolated enum ChargerAmenity: String, Codable, Sendable {
    case restrooms, food, wifi, shopping, lodging, park
}

nonisolated enum ChargerStatus: String, Codable, Sendable {
    case operational, limited, offline, congested
}
