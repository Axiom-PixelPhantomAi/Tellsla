import SwiftUI
import MapKit

struct iPadLayout: View {
    @State private var selectedTab: String = "navigate"
    @State private var showDetailPanel = true
    @Bindable var appState: AppState
    @State private var locationService: LocationService
    @State private var navViewModel: NavigationViewModel
    @State private var routinesViewModel = RoutinesViewModel()
    @State private var energyViewModel = EnergyViewModel()
    @State private var vehicleViewModel = VehicleViewModel()
    @State private var communityViewModel = CommunityViewModel()

    init(appState: AppState) {
        _appState = Bindable(wrappedValue: appState)
        let loc = LocationService()
        _locationService = State(initialValue: loc)
        _navViewModel = State(initialValue: NavigationViewModel(locationService: loc))
    }

    var body: some View {
        NavigationSplitView {
            // Sidebar
            List(selection: $selectedTab) {
                Section("Navigation") {
                    NavigationLink(value: "navigate") {
                        Label("Navigate", systemImage: "map")
                    }
                    NavigationLink(value: "energy") {
                        Label("Energy", systemImage: "battery.75")
                    }
                }
                
                Section("Automation") {
                    NavigationLink(value: "routines") {
                        Label("Routines", systemImage: "repeat")
                    }
                    NavigationLink(value: "community") {
                        Label("Community", systemImage: "person.2")
                    }
                }
                
                Section("Vehicle") {
                    NavigationLink(value: "vehicle") {
                        Label("Status", systemImage: "car")
                    }
                    NavigationLink(value: "settings") {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            .navigationSplitViewColumnWidth(250)
        } detail: {
            // Main content
            ZStack {
                switch selectedTab {
                case "navigate":
                    NavigateTabView(viewModel: navViewModel, locationService: locationService, appState: appState)
                case "energy":
                    EnergyTabView(viewModel: energyViewModel, vehicle: appState.selectedVehicle, appState: appState)
                case "routines":
                    RoutinesTabView(viewModel: routinesViewModel, appState: appState)
                case "community":
                    CommunityTabView(viewModel: communityViewModel, locationService: locationService, appState: appState)
                case "vehicle":
                    VehicleTabView(viewModel: vehicleViewModel, vehicle: appState.selectedVehicle, appState: appState)
                case "settings":
                    SettingsView(appState: appState)
                default:
                    Text("Select a tab")
                }
            }
            .navigationTitle(selectedTab.capitalized)
        }
        .navigationSplitViewStyle(.prominentDetail)
    }
}

// iPad detail panel for vehicle controls
struct iPadDetailPanel: View {
    let vehicle: Vehicle
    
    var body: some View {
        VStack(spacing: 20) {
            // Battery status
            VStack(spacing: 12) {
                Text("Battery Status")
                    .font(.headline)
                
                HStack {
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemFill), lineWidth: 8)
                        Circle()
                            .trim(from: 0, to: Double(vehicle.batteryLevel) / 100)
                            .stroke(.green, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 0) {
                            Text("\(vehicle.batteryLevel)")
                                .font(.system(size: 24, weight: .bold))
                            Text("%")
                                .font(.caption)
                        }
                    }
                    .frame(width: 100, height: 100)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Range")
                            Spacer()
                            Text("\(Int(vehicle.batteryRange)) mi")
                        }
                        
                        HStack {
                            Text("State")
                            Spacer()
                            Text(vehicle.chargingState.rawValue.capitalized)
                        }
                        
                        HStack {
                            Text("Limit")
                            Spacer()
                            Text("\(vehicle.chargeLimit)%")
                        }
                    }
                    .font(.subheadline)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            // Vehicle controls
            VStack(spacing: 12) {
                Text("Controls")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    Button(action: {}) {
                        VStack(spacing: 8) {
                            Image(systemName: "lock.fill")
                                .font(.title2)
                            Text("Lock")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Button(action: {}) {
                        VStack(spacing: 8) {
                            Image(systemName: "thermometer.half")
                                .font(.title2)
                            Text("Climate")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Button(action: {}) {
                        VStack(spacing: 8) {
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.title2)
                            Text("Horn")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
            
            Spacer()
        }
        .padding()
    }
}
