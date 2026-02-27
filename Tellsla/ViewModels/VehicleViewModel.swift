import SwiftUI

@Observable
@MainActor
class VehicleViewModel {
    var isLocking: Bool = false
    var isTogglingClimate: Bool = false
    var isToggingSentry: Bool = false
    var sentryEvents: [SentryEvent] = []
    var showCommandConfirmation: Bool = false
    var lastCommandResult: String?
    var isLoading: Bool = false

    func lockVehicle(_ vehicle: Vehicle) async {
        isLocking = true
        defer { isLocking = false }
        do {
            try await TeslaAPIService.shared.lockDoors(vehicleId: vehicle.id)
            lastCommandResult = "Vehicle locked"
            showCommandConfirmation = true
        } catch {
            lastCommandResult = "Failed to lock"
            showCommandConfirmation = true
            await CrashLogService.shared.log(.error, message: "Lock failed: \(error.localizedDescription)", context: "VehicleVM")
        }
    }

    func unlockVehicle(_ vehicle: Vehicle) async {
        isLocking = true
        defer { isLocking = false }
        do {
            try await TeslaAPIService.shared.unlockDoors(vehicleId: vehicle.id)
            lastCommandResult = "Vehicle unlocked"
            showCommandConfirmation = true
        } catch {
            lastCommandResult = "Failed to unlock"
            showCommandConfirmation = true
            await CrashLogService.shared.log(.error, message: "Unlock failed: \(error.localizedDescription)", context: "VehicleVM")
        }
    }

    func toggleClimate(_ vehicle: Vehicle) async {
        isTogglingClimate = true
        defer { isTogglingClimate = false }
        do {
            if vehicle.isClimateOn {
                try await TeslaAPIService.shared.stopClimate(vehicleId: vehicle.id)
                lastCommandResult = "Climate off"
            } else {
                try await TeslaAPIService.shared.startClimate(vehicleId: vehicle.id)
                lastCommandResult = "Climate on"
            }
            showCommandConfirmation = true
        } catch {
            lastCommandResult = "Climate command failed"
            showCommandConfirmation = true
            await CrashLogService.shared.log(.error, message: "Climate toggle failed", context: "VehicleVM")
        }
    }

    func toggleSentry(_ vehicle: Vehicle) async {
        isToggingSentry = true
        defer { isToggingSentry = false }
        do {
            try await TeslaAPIService.shared.setSentryMode(vehicleId: vehicle.id, enabled: !vehicle.sentryModeActive)
            lastCommandResult = vehicle.sentryModeActive ? "Sentry off" : "Sentry on"
            showCommandConfirmation = true
        } catch {
            lastCommandResult = "Sentry command failed"
            showCommandConfirmation = true
            await CrashLogService.shared.log(.error, message: "Sentry toggle failed", context: "VehicleVM")
        }
    }

    func flashLights(_ vehicle: Vehicle) async {
        do {
            try await TeslaAPIService.shared.flashLights(vehicleId: vehicle.id)
        } catch {}
    }

    func honkHorn(_ vehicle: Vehicle) async {
        do {
            try await TeslaAPIService.shared.honkHorn(vehicleId: vehicle.id)
        } catch {}
    }

    func openFrunk(_ vehicle: Vehicle) async {
        do {
            try await TeslaAPIService.shared.openTrunk(vehicleId: vehicle.id, which: "front")
            lastCommandResult = "Frunk opened"
            showCommandConfirmation = true
        } catch {
            lastCommandResult = "Failed to open frunk"
            showCommandConfirmation = true
        }
    }

    func openTrunk(_ vehicle: Vehicle) async {
        do {
            try await TeslaAPIService.shared.openTrunk(vehicleId: vehicle.id, which: "rear")
            lastCommandResult = "Trunk opened"
            showCommandConfirmation = true
        } catch {
            lastCommandResult = "Failed to open trunk"
            showCommandConfirmation = true
        }
    }
}

nonisolated struct SentryEvent: Identifiable, Sendable {
    let id: String
    let timestamp: Date
    let type: SentryEventType
    let thumbnailURL: String?
    let description: String
    let isVerifiedThreat: Bool
    let location: String?
}

nonisolated enum SentryEventType: String, Sendable {
    case personApproaching, vehicleTouch, collision, weather, animal, unknown
}
