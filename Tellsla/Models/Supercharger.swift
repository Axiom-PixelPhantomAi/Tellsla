import Foundation
import CoreLocation
import MapKit

nonisolated final class Supercharger: NSObject, Codable, Identifiable, MKAnnotation {
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
    
    var title: String? {
        name
    }
    
    var subtitle: String? {
        address
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
    
    // Initializer for creating Supercharger instances
    init(id: String, name: String, address: String, latitude: Double, longitude: Double, 
         totalStalls: Int, availableStalls: Int, maxPowerKW: Int, pricePerKWh: Double?,
         amenities: [ChargerAmenity], status: ChargerStatus, distanceMiles: Double?, 
         estimatedWaitMinutes: Int?) {
        self.id = id
        self.name = name
        self.address = address
        self.latitude = latitude
        self.longitude = longitude
        self.totalStalls = totalStalls
        self.availableStalls = availableStalls
        self.maxPowerKW = maxPowerKW
        self.pricePerKWh = pricePerKWh
        self.amenities = amenities
        self.status = status
        self.distanceMiles = distanceMiles
        self.estimatedWaitMinutes = estimatedWaitMinutes
        super.init()
    }
}

nonisolated enum ChargerAmenity: String, Codable, Sendable {
    case restrooms, food, wifi, shopping, lodging, park
}

nonisolated enum ChargerStatus: String, Codable, Sendable {
    case operational, limited, offline, congested
}
