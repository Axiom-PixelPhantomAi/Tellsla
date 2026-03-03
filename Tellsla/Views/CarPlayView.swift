import SwiftUI
import MapKit

// CarPlay template view for iOS 17+
struct CarPlayMapTemplate: View {
    @State private var vehicles: [Vehicle] = []
    @State private var selectedVehicle: Vehicle?
    @State private var superchargers: [Supercharger] = []
    @State private var mapPosition: MapCameraPosition = .automatic
    
    var body: some View {
        ZStack {
            // Map background
            Map(position: $mapPosition) {
                ForEach(superchargers, id: \.id) { sc in
                    Annotation("", coordinate: sc.coordinate) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.red)
                            .font(.title)
                    }
                }
            }
            .ignoresSafeArea()
            
            // Top bar - Vehicle selector
            VStack {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedVehicle?.displayName ?? "Tesla")
                            .font(.headline)
                        HStack(spacing: 12) {
                            HStack(spacing: 4) {
                                Image(systemName: "bolt.fill")
                                    .font(.caption)
                                Text("\(selectedVehicle?.batteryLevel ?? 0)%")
                                    .font(.caption)
                            }
                            
                            HStack(spacing: 4) {
                                Image(systemName: "road.lanes")
                                    .font(.caption)
                                Text("\(Int(selectedVehicle?.batteryRange ?? 0)) mi")
                                    .font(.caption)
                            }
                        }
                        .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Button(action: {}) {
                            Image(systemName: "thermometer.half")
                                .frame(width: 44, height: 44)
                        }
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                        
                        Button(action: {}) {
                            Image(systemName: "lock.fill")
                                .frame(width: 44, height: 44)
                        }
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.6))
                
                Spacer()
                
                // Bottom bar - Nearby Superchargers
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nearby Superchargers")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    
                    ScrollView(.horizontal) {
                        HStack(spacing: 12) {
                            ForEach(superchargers.prefix(3), id: \.id) { sc in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(sc.name)
                                        .font(.caption.weight(.semibold))
                                    Text("\(sc.availableStalls)/\(sc.totalStalls) stalls")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Text("\(String(format: "%.1f", sc.distanceMiles ?? 0)) mi")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                                .padding(8)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.black.opacity(0.6))
            }
        }
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        Task {
            do {
                vehicles = try await TeslaAPIService.shared.fetchVehicles()
                if let first = vehicles.first {
                    selectedVehicle = first
                    superchargers = try await TeslaAPIService.shared.fetchNearbySuperchargers(
                        latitude: first.location?.latitude ?? 37.7749,
                        longitude: first.location?.longitude ?? -122.4194
                    )
                }
            } catch {}
        }
    }
}

// CarPlay scene (iOS 17+)
struct CarPlayScene: Scene {
    var body: some Scene {
        WindowGroup {
            CarPlayMapTemplate()
        }
    }
}
