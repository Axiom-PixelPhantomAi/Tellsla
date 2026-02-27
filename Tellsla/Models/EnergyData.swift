import Foundation

nonisolated struct EnergyData: Codable, Sendable {
    var currentChargeRate: Double
    var timeToFullCharge: Double
    var energyAddedKWh: Double
    var chargingCostEstimate: Double
    var homeGridStatus: GridStatus
    var solarProductionWatts: Double?
    var homeConsumptionWatts: Double?
    var gridPricePerKWh: Double
    var peakPricePerKWh: Double
    var offPeakPricePerKWh: Double
    var currentRateType: RateType
    var optimalChargeTime: Date?
    var dailyEnergyHistory: [EnergyHistoryPoint]
    var projectedSavings: Double
}

nonisolated struct EnergyHistoryPoint: Codable, Identifiable, Sendable {
    let id: String
    var timestamp: Date
    var chargeLevel: Int
    var solarWatts: Double
    var gridWatts: Double
    var pricePerKWh: Double
}

nonisolated enum GridStatus: String, Codable, Sendable {
    case normal, peak, offPeak, solar, gridDown
}

nonisolated enum RateType: String, Codable, Sendable {
    case peak = "Peak"
    case offPeak = "Off-Peak"
    case superOffPeak = "Super Off-Peak"
    case solar = "Solar"
}

nonisolated struct TripEnergyEstimate: Codable, Sendable {
    var distanceMiles: Double
    var estimatedKWh: Double
    var estimatedCost: Double
    var batteryAtDestination: Int
    var needsCharging: Bool
    var recommendedChargeStops: [String]
    var alternateRouteAvailable: Bool
    var alternateRouteSavingKWh: Double?
}

nonisolated struct FleetVehicleSummary: Codable, Identifiable, Sendable {
    let id: String
    var vehicleName: String
    var batteryLevel: Int
    var isCharging: Bool
    var isAvailable: Bool
    var currentLocation: String?
    var recommendedForTrip: Bool
    var estimatedRangeAfterTrip: Int?
}

nonisolated struct MaintenancePrediction: Codable, Identifiable, Sendable {
    let id: String
    var component: MaintenanceComponent
    var currentCondition: Double
    var predictedReplacementDate: Date
    var urgency: MaintenanceUrgency
    var estimatedCost: Double
    var recommendation: String
    var basedOnMiles: Double
    var basedOnDrivingStyle: String
}

nonisolated enum MaintenanceComponent: String, Codable, Sendable, CaseIterable {
    case tireFL = "Front Left Tire"
    case tireFR = "Front Right Tire"
    case tireRL = "Rear Left Tire"
    case tireRR = "Rear Right Tire"
    case brakePadFront = "Front Brake Pads"
    case brakePadRear = "Rear Brake Pads"
    case cabinFilter = "Cabin Air Filter"
    case wiperBlades = "Wiper Blades"
    case battery12V = "12V Battery"
    case coolant = "Coolant"

    var icon: String {
        switch self {
        case .tireFL, .tireFR, .tireRL, .tireRR: return "circle.circle"
        case .brakePadFront, .brakePadRear: return "circle.slash"
        case .cabinFilter: return "aqi.medium"
        case .wiperBlades: return "wiper.vertical.and.water"
        case .battery12V: return "battery.100percent"
        case .coolant: return "drop.fill"
        }
    }
}

nonisolated enum MaintenanceUrgency: String, Codable, Sendable {
    case good, monitor, soon, urgent
}
