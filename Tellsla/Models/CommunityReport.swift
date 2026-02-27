import Foundation
import CoreLocation

nonisolated struct CommunityReport: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var type: ReportType
    var latitude: Double
    var longitude: Double
    var heading: Double?
    var description: String
    var reporterDisplayName: String
    var vehicleModel: TeslaModel?
    var upvotes: Int
    var downvotes: Int
    var isVerified: Bool
    var createdAt: Date
    var expiresAt: Date?
    var imageURL: String?

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var isExpired: Bool {
        guard let expires = expiresAt else { return false }
        return Date() > expires
    }

    var reliability: Double {
        let total = upvotes + downvotes
        guard total > 0 else { return 0.5 }
        return Double(upvotes) / Double(total)
    }
}

nonisolated enum ReportType: String, Codable, Sendable, CaseIterable {
    case pothole = "Pothole"
    case roadHazard = "Road Hazard"
    case construction = "Construction"
    case accident = "Accident"
    case police = "Police"
    case speedTrap = "Speed Trap"
    case brokenCharger = "Broken Charger"
    case roadClosure = "Road Closure"
    case poorRoadSurface = "Poor Road Surface"
    case flooding = "Flooding"
    case iceSnow = "Ice/Snow"
    case debris = "Debris"

    var icon: String {
        switch self {
        case .pothole: return "circle.dotted"
        case .roadHazard: return "exclamationmark.triangle.fill"
        case .construction: return "cone.fill"
        case .accident: return "car.2.fill"
        case .police: return "shield.fill"
        case .speedTrap: return "gauge.with.dots.needle.33percent"
        case .brokenCharger: return "bolt.slash.fill"
        case .roadClosure: return "xmark.octagon.fill"
        case .poorRoadSurface: return "road.lanes"
        case .flooding: return "water.waves"
        case .iceSnow: return "snowflake"
        case .debris: return "leaf.fill"
        }
    }

    var defaultExpiry: TimeInterval {
        switch self {
        case .pothole, .poorRoadSurface, .construction: return 7 * 24 * 3600
        case .accident, .debris, .flooding: return 4 * 3600
        case .police, .speedTrap: return 1 * 3600
        case .roadHazard, .roadClosure: return 24 * 3600
        case .brokenCharger: return 48 * 3600
        case .iceSnow: return 12 * 3600
        }
    }
}
