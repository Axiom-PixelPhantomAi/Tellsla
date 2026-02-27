import SwiftUI

@Observable
@MainActor
class EnergyViewModel {
    var energyData: EnergyData?
    var maintenancePredictions: [MaintenancePrediction] = []
    var fleetSummary: [FleetVehicleSummary] = []
    var chargingSessions: [ChargingSession] = []
    var isLoading: Bool = false
    var selectedTimeRange: EnergyTimeRange = .week
    var showSmartChargingTip: Bool = true
    var optimalChargeMessage: String?

    init() {
        loadChargingSessions()
    }

    func loadEnergyData() async {
        isLoading = true
        isLoading = false
    }

    func loadMaintenancePredictions() async {
        isLoading = true
        isLoading = false
    }

    func loadFleetSummary() async {
        isLoading = true
        isLoading = false
    }

    func dismissSmartChargingTip() {
        withAnimation(.snappy) {
            showSmartChargingTip = false
        }
    }

    private func loadChargingSessions() {
        if let data = UserDefaults.standard.data(forKey: "charging_sessions"),
           let decoded = try? JSONDecoder().decode([ChargingSession].self, from: data) {
            chargingSessions = decoded
        }
    }
}

nonisolated enum EnergyTimeRange: String, CaseIterable, Sendable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}
