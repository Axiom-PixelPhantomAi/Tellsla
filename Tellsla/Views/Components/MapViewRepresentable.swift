import SwiftUI
import MapKit

struct MapViewRepresentable: UIViewRepresentable {
    @Binding var mapType: MKMapType
    @Binding var selectedSupercharger: Supercharger?
    let superchargers: [Supercharger]
    let vehicleLocation: CLLocationCoordinate2D?
    let routeOverlay: MKRoute?
    let showRangeCircle: Bool
    let rangePercentage: Double

    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: MapViewRepresentable
        var rangeCircle: MKCircle?

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil // Use default blue dot
            }

            if let supercharger = annotation as? SuperchargerAnnotation {
                let identifier = "supercharger"
                var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

                if view == nil {
                    view = MKMarkerAnnotationView(annotation: supercharger, reuseIdentifier: identifier)
                    view?.markerTintColor = UIColor(red: 1, green: 0.2, blue: 0.2, alpha: 1) // Tesla red
                    view?.glyphText = "⚡"
                }

                view?.annotation = supercharger
                return view
            }

            return nil
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(red: 0, green: 0.5, blue: 1, alpha: 0.8)
                renderer.lineWidth = 4
                return renderer
            }

            if let circle = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circle)
                
                let percentage = parent.rangePercentage
                if percentage > 0.5 {
                    renderer.fillColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.15)
                    renderer.strokeColor = UIColor(red: 0, green: 1, blue: 0, alpha: 0.5)
                } else if percentage > 0.2 {
                    renderer.fillColor = UIColor(red: 1, green: 1, blue: 0, alpha: 0.15)
                    renderer.strokeColor = UIColor(red: 1, green: 1, blue: 0, alpha: 0.5)
                } else {
                    renderer.fillColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.15)
                    renderer.strokeColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.5)
                }
                
                renderer.lineWidth = 2
                return renderer
            }

            return MKOverlayRenderer(overlay: overlay)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.mapType = mapType
        mapView.isPitchEnabled = true
        mapView.isRotateEnabled = true
        mapView.showsUserLocation = true

        // Set default camera
        let initialLocation = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194) // SF default
        let region = MKCoordinateRegion(
            center: initialLocation,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapView.setRegion(region, animated: true)

        // Set camera angle
        var camera = mapView.camera
        camera.pitch = 45
        camera.altitude = 800
        mapView.setCamera(camera, animated: false)

        // Add Supercharger annotations
        mapView.addAnnotations(superchargers.map(SuperchargerAnnotation.init))

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.mapType = mapType

        // Update vehicle location
        if let vehicleLocation = vehicleLocation {
            let region = MKCoordinateRegion(
                center: vehicleLocation,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            )
            mapView.setRegion(region, animated: true)
        }

        // Update route overlay
        if let route = routeOverlay {
            mapView.addOverlay(route.polyline)
        } else {
            mapView.overlays.forEach { overlay in
                if overlay is MKPolyline {
                    mapView.removeOverlay(overlay)
                }
            }
        }

        // Update range circle
        if showRangeCircle, let vehicleLocation = vehicleLocation {
            // Estimate range (rough calculation: miles per percent * remaining battery)
            let rangeInMiles = (250 * rangePercentage / 100) // Assume 250 mi range at 100%
            let rangeInMeters = rangeInMiles * 1609.34

            if let existing = context.coordinator.rangeCircle {
                mapView.removeOverlay(existing)
            }

            let circle = MKCircle(center: vehicleLocation, radius: rangeInMeters)
            context.coordinator.rangeCircle = circle
            mapView.addOverlay(circle)
        } else {
            if let existing = context.coordinator.rangeCircle {
                mapView.removeOverlay(existing)
                context.coordinator.rangeCircle = nil
            }
        }
    }
}

// Vehicle pin annotation
class VehicleAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
}

// Supercharger annotation wrapper (MKAnnotation requires a class)
final class SuperchargerAnnotation: NSObject, MKAnnotation {
    let supercharger: Supercharger

    init(_ supercharger: Supercharger) {
        self.supercharger = supercharger
        super.init()
    }

    var coordinate: CLLocationCoordinate2D { supercharger.coordinate }
    var title: String? { supercharger.name }
    var subtitle: String? {
        let price = supercharger.pricePerKWh.map { "\(String(format: "%.0f", $0 * 100))¢/kWh" } ?? ""
        return "\(supercharger.availableStalls) of \(supercharger.totalStalls) stalls\(price.isEmpty ? "" : " • \(price)")"
    }
}
