import Foundation
import CoreLocation
import MapKit

@Observable
class LocationService: NSObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    var location: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var placeName: String = ""
    var searchResults: [MKMapItem] = []
    var searchCompletions: [MKLocalSearchCompletion] = []

    private let geocoder = CLGeocoder()
    private let searchCompleter = MKLocalSearchCompleter()

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
        manager.requestLocation()
    }

    func startContinuousUpdates() {
        manager.startUpdatingLocation()
    }

    func stopContinuousUpdates() {
        manager.stopUpdatingLocation()
    }

    func searchPlaces(_ query: String) {
        searchCompleter.queryFragment = query
    }

    func performSearch(_ query: String, near coordinate: CLLocationCoordinate2D? = nil) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let coord = coordinate ?? location?.coordinate {
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

    func reverseGeocode(_ location: CLLocation) async -> String {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else { return "Unknown" }
            return placemark.locality ?? placemark.administrativeArea ?? "Unknown"
        } catch {
            return "Unknown"
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            self.location = locations.last
            if let loc = locations.last {
                self.placeName = await self.reverseGeocode(loc)
            }
        }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse ||
               manager.authorizationStatus == .authorizedAlways {
                self.requestLocation()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}

extension LocationService: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            self.searchCompletions = completer.results
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {}
}
