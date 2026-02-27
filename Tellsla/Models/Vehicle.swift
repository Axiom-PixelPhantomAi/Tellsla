import Foundation
import CoreLocation

nonisolated struct Vehicle: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var displayName: String
    var vin: String
    var model: TeslaModel
    var year: Int
    var color: String
    var batteryLevel: Int
    var batteryRange: Double
    var isCharging: Bool
    var chargingState: ChargingState
    var chargeLimit: Int
    var isLocked: Bool
    var isClimateOn: Bool
    var interiorTemp: Double
    var exteriorTemp: Double
    var odometer: Double
    var softwareVersion: String
    var sentryModeActive: Bool
    var latitude: Double
    var longitude: Double
    var heading: Double
    var speed: Int
    var shiftState: ShiftState?
    var tirePressures: TirePressures
    var lastSeen: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    var isParked: Bool {
        shiftState == nil || shiftState == .park
    }
}

nonisolated enum TeslaModel: String, Codable, Sendable, CaseIterable {
    case modelS = "Model S"
    case model3 = "Model 3"
    case modelX = "Model X"
    case modelY = "Model Y"
    case cybertruck = "Cybertruck"
    case semi = "Semi"
}

nonisolated enum ChargingState: String, Codable, Sendable {
    case disconnected = "Disconnected"
    case charging = "Charging"
    case complete = "Complete"
    case stopped = "Stopped"
    case pending = "Pending"
}

nonisolated enum ShiftState: String, Codable, Sendable {
    case park = "P"
    case drive = "D"
    case reverse = "R"
    case neutral = "N"
}

nonisolated struct TirePressures: Codable, Hashable, Sendable {
    var frontLeft: Double
    var frontRight: Double
    var rearLeft: Double
    var rearRight: Double

    func status(for pressure: Double) -> TirePressureStatus {
        if pressure < 30 { return .low }
        if pressure > 45 { return .high }
        return .normal
    }
}

nonisolated enum TirePressureStatus: String, Sendable {
    case low, normal, high
}
