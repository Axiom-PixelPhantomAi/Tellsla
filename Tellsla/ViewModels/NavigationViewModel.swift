import SwiftUI
import MapKit

@Observable
@MainActor
class NavigationViewModel {
    var searchText: String = ""
    var isSearching: Bool = false
    var isNavigating: Bool = false
    var searchResults: [MKMapItem] = []
    var selectedDestination: MKMapItem?
    var route: MKRoute?
    var superchargers: [Supercharger] = []
    var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    var tripEstimate: TripEnergyEstimate?
    var recentDestinations: [RecentDestination] = []
    var quickDestinations: [QuickDestination] = []

    private let locationService: LocationService

    init(locationService: LocationService) {
        self.locationService = locationService
        loadQuickDestinations()
        loadRecentDestinations()
    }

    func search(_ query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        isSearching = true
        defer { isSearching = false }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let coord = locationService.location?.coordinate {
            request.region = MKCoordinateRegion(
                center: coord,
                span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
            )
        }

        do {
            let search = MKLocalSearch(request: request)
            let response = try await search.start()
            searchResults = response.mapItems
        } catch {
            searchResults = []
        }
    }

    func calculateRoute(to destination: MKMapItem) async {
        guard let userLocation = locationService.location?.coordinate else { return }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: userLocation))
        request.destination = destination
        request.transportType = .automobile
        request.requestsAlternateRoutes = true

        do {
            let directions = MKDirections(request: request)
            let response = try await directions.calculate()
            route = response.routes.first
            selectedDestination = destination

            if let route = route {
                let distanceMiles = route.distance / 1609.34
                tripEstimate = TripEnergyEstimate(
                    distanceMiles: distanceMiles,
                    estimatedKWh: distanceMiles * 0.28,
                    estimatedCost: distanceMiles * 0.28 * 0.12,
                    batteryAtDestination: max(0, 80 - Int(distanceMiles / 3.0)),
                    needsCharging: distanceMiles > 200,
                    recommendedChargeStops: distanceMiles > 200 ? ["Supercharger en route"] : [],
                    alternateRouteAvailable: response.routes.count > 1,
                    alternateRouteSavingKWh: response.routes.count > 1 ? 2.1 : nil
                )
            }

            addRecentDestination(destination)
        } catch {}
    }

    func startNavigation() {
        isNavigating = true
        if let route = route {
            let span = route.polyline.boundingMapRect
            cameraPosition = .rect(span)
        }
    }

    func stopNavigation() {
        isNavigating = false
        route = nil
        selectedDestination = nil
        tripEstimate = nil
        cameraPosition = .userLocation(fallback: .automatic)
    }

    func loadNearbySuperchargers() async {
        guard let coord = locationService.location?.coordinate else { return }
        do {
            superchargers = try await TeslaAPIService.shared.fetchNearbySuperchargers(
                latitude: coord.latitude,
                longitude: coord.longitude
            )
        } catch {}
    }

    func centerOnUser() {
        cameraPosition = .userLocation(fallback: .automatic)
    }

    private func loadQuickDestinations() {
        quickDestinations = [
            QuickDestination(id: "home", name: "Home", icon: "house.fill", subtitle: "Set in Settings"),
            QuickDestination(id: "work", name: "Work", icon: "briefcase.fill", subtitle: "Set in Settings"),
            QuickDestination(id: "charger", name: "Charger", icon: "bolt.fill", subtitle: "Nearest"),
        ]
    }

    private func loadRecentDestinations() {
        if let data = UserDefaults.standard.data(forKey: "recentDestinations"),
           let decoded = try? JSONDecoder().decode([RecentDestination].self, from: data) {
            recentDestinations = decoded
        }
    }

    private func addRecentDestination(_ mapItem: MKMapItem) {
        let recent = RecentDestination(
            id: UUID().uuidString,
            name: mapItem.name ?? "Unknown",
            address: mapItem.placemark.title ?? "",
            latitude: mapItem.placemark.coordinate.latitude,
            longitude: mapItem.placemark.coordinate.longitude,
            visitedAt: Date()
        )
        recentDestinations.insert(recent, at: 0)
        if recentDestinations.count > 20 {
            recentDestinations = Array(recentDestinations.prefix(20))
        }
        if let data = try? JSONEncoder().encode(recentDestinations) {
            UserDefaults.standard.set(data, forKey: "recentDestinations")
        }
    }
}

nonisolated struct QuickDestination: Identifiable, Sendable {
    let id: String
    let name: String
    let icon: String
    let subtitle: String
}

nonisolated struct RecentDestination: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
    let visitedAt: Date
}
