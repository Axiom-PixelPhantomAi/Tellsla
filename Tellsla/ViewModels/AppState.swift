import SwiftUI

@Observable
@MainActor
class AppState {
    var isAuthenticated: Bool = false
    var hasCompletedOnboarding: Bool = false
    var currentUser: UserAccount?
    var vehicles: [Vehicle] = []
    var selectedVehicle: Vehicle?
    var isLoading: Bool = false
    var errorMessage: String?
    var showError: Bool = false
    var selectedTab: AppTab = .navigate
    var showTutorial: Bool = false
    var tutorialSection: String?
    var globalSuperchargers: [Supercharger] = []
    var selectedMapType: MapType = .hybridFlyover
    var showWeatherOverlay: Bool = false
    var showRangeCircle: Bool = false
    var showPOILayer: Bool = true
    var weatherInfo: WeatherInfo?
    var isOffline: Bool = false
    var requireBiometric: Bool = false
    var biometricUnlocked: Bool = false

    init() {
        isAuthenticated = KeychainService.hasValidToken()
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        if let raw = UserDefaults.standard.string(forKey: "preferredMapType"),
           let type = MapType(rawValue: raw) {
            selectedMapType = type
        }
        showWeatherOverlay = UserDefaults.standard.bool(forKey: "showWeatherOverlay")
        showRangeCircle = UserDefaults.standard.bool(forKey: "showRangeCircle")
        requireBiometric = UserDefaults.standard.bool(forKey: "requireBiometric")
    }

    func loadVehicles() async {
        isLoading = true
        defer { isLoading = false }
        do {
            vehicles = try await TeslaAPIService.shared.fetchVehicles()
            if selectedVehicle == nil {
                selectedVehicle = vehicles.first
            }
        } catch {
            await CrashLogService.shared.log(.error, message: "Failed to load vehicles: \(error.localizedDescription)", context: "AppState.loadVehicles")
            handleError(error)
        }
    }

    func loadGlobalSuperchargers(latitude: Double, longitude: Double) async {
        do {
            globalSuperchargers = try await TeslaAPIService.shared.fetchNearbySuperchargers(
                latitude: latitude, longitude: longitude
            )
        } catch {
            await CrashLogService.shared.log(.warning, message: "Failed to load superchargers", context: "AppState.loadGlobalSuperchargers")
        }
    }

    func refreshVehicleData() async {
        guard let vehicle = selectedVehicle else { return }
        do {
            let updated = try await TeslaAPIService.shared.fetchVehicleData(vehicleId: vehicle.id)
            selectedVehicle = updated
            if let index = vehicles.firstIndex(where: { $0.id == vehicle.id }) {
                vehicles[index] = updated
            }
        } catch let error as TeslaAPIError {
            if case .vehicleAsleep = error {
                try? await TeslaAPIService.shared.wakeUp(vehicleId: vehicle.id)
                try? await Task.sleep(for: .seconds(5))
                await refreshVehicleData()
            } else {
                handleError(error)
            }
        } catch {
            handleError(error)
        }
    }

    func logout() {
        Task {
            await AuthenticationService.shared.logout()
        }
        isAuthenticated = false
        currentUser = nil
        vehicles = []
        selectedVehicle = nil
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    func replayOnboarding() {
        hasCompletedOnboarding = false
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }

    func setMapType(_ type: MapType) {
        selectedMapType = type
        UserDefaults.standard.set(type.rawValue, forKey: "preferredMapType")
    }

    func toggleWeather() {
        showWeatherOverlay.toggle()
        UserDefaults.standard.set(showWeatherOverlay, forKey: "showWeatherOverlay")
    }

    func toggleRangeCircle() {
        showRangeCircle.toggle()
        UserDefaults.standard.set(showRangeCircle, forKey: "showRangeCircle")
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}

nonisolated enum AppTab: String, CaseIterable, Sendable {
    case navigate, energy, routines, vehicle, community, profile

    var title: String {
        switch self {
        case .navigate: return "Navigate"
        case .energy: return "Energy"
        case .routines: return "Routines"
        case .vehicle: return "Vehicle"
        case .community: return "Community"
        case .profile: return "Profile"
        }
    }

    var icon: String {
        switch self {
        case .navigate: return "map.fill"
        case .energy: return "bolt.fill"
        case .routines: return "gearshape.2.fill"
        case .vehicle: return "car.fill"
        case .community: return "person.3.fill"
        case .profile: return "person.circle.fill"
        }
    }
}
