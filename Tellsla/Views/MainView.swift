import SwiftUI
import MapKit

struct MainView: View {
    @State private var appState: AppState
    @State private var locationService = LocationService()
    @State private var navViewModel: NavigationViewModel
    @State private var routinesViewModel = RoutinesViewModel()
    @State private var energyViewModel = EnergyViewModel()
    @State private var vehicleViewModel = VehicleViewModel()
    @State private var communityViewModel = CommunityViewModel()
    @State private var sheetDetent: PresentationDetent = .fraction(0.4)
    @State private var showMapTypePicker: Bool = false
    @State private var showSuperchargerDetail: Supercharger?

    init(appState: AppState) {
        let locService = LocationService()
        _appState = State(initialValue: appState)
        _locationService = State(initialValue: locService)
        _navViewModel = State(initialValue: NavigationViewModel(locationService: locService))
    }

    var body: some View {
        ZStack {
            mapLayer

            VStack {
                if !NetworkMonitor.shared.isConnected {
                    offlineBanner
                }
                if navViewModel.isNavigating {
                    navigationBanner
                }
                Spacer()
            }

            VStack {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        mapButton(icon: "location.fill") {
                            navViewModel.centerOnUser()
                        }
                        mapButton(icon: appState.selectedMapType.icon) {
                            showMapTypePicker = true
                        }
                        mapButton(icon: appState.showWeatherOverlay ? "cloud.fill" : "cloud") {
                            appState.toggleWeather()
                            if appState.showWeatherOverlay {
                                loadWeather()
                            }
                        }
                        mapButton(icon: appState.showRangeCircle ? "circle.dashed.inset.filled" : "circle.dashed") {
                            appState.toggleRangeCircle()
                        }
                        mapButton(icon: "gearshape.fill") {
                            appState.showTutorial = true
                            appState.tutorialSection = "navigate"
                        }
                    }
                }
                .padding(.trailing, 12)
                .padding(.top, 60)
                Spacer()
            }

            if appState.showWeatherOverlay, let weather = appState.weatherInfo {
                VStack {
                    weatherCard(weather)
                    Spacer()
                }
                .padding(.top, 60)
                .padding(.leading, 16)
                .allowsHitTesting(false)
            }

            if let routine = routinesViewModel.activeRoutine {
                routineActiveBanner(routine)
            }
        }
        .sheet(isPresented: .constant(true)) {
            bottomSheetContent
                .presentationDetents([.fraction(0.12), .fraction(0.4), .large], selection: $sheetDetent)
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.4)))
                .presentationContentInteraction(.scrolls)
                .presentationCornerRadius(24)
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showMapTypePicker) {
            MapTypePickerSheet(appState: appState)
                .presentationDetents([.fraction(0.4)])
        }
        .sheet(item: $showSuperchargerDetail) { charger in
            SuperchargerDetailSheet(charger: charger, navViewModel: navViewModel)
                .presentationDetents([.fraction(0.5)])
        }
        .sheet(isPresented: $appState.showTutorial) {
            TutorialSheetView(section: appState.tutorialSection ?? "welcome")
        }
        .onAppear {
            locationService.requestPermission()
        }
        .task {
            await appState.loadVehicles()
            await navViewModel.loadNearbySuperchargers()
            if let coord = locationService.location?.coordinate {
                await appState.loadGlobalSuperchargers(latitude: coord.latitude, longitude: coord.longitude)
            }
            if appState.showWeatherOverlay { loadWeather() }
        }
        .preferredColorScheme(.dark)
    }

    private var mapLayer: some View {
        Map(position: $navViewModel.cameraPosition) {
            UserAnnotation()

            if let vehicle = appState.selectedVehicle, vehicle.latitude != 0 {
                Annotation("My Tesla", coordinate: vehicle.coordinate) {
                    VehiclePinView(vehicle: vehicle)
                }
            }

            ForEach(appState.globalSuperchargers) { charger in
                Annotation(charger.name, coordinate: charger.coordinate) {
                    Button {
                        showSuperchargerDetail = charger
                    } label: {
                        SuperchargerMapPin(charger: charger)
                    }
                }
            }

            ForEach(communityViewModel.filteredReports) { report in
                Annotation("", coordinate: report.coordinate) {
                    ReportMapPin(report: report)
                }
            }

            if let route = navViewModel.route {
                MapPolyline(route.polyline)
                    .stroke(.blue, lineWidth: 5)
            }

            if appState.showRangeCircle, let vehicle = appState.selectedVehicle, vehicle.latitude != 0 {
                MapCircle(center: vehicle.coordinate, radius: rangeRadius(for: vehicle))
                    .foregroundStyle(rangeColor(for: vehicle).opacity(0.1))
                    .stroke(rangeColor(for: vehicle).opacity(0.5), lineWidth: 2)
            }
        }
        .mapStyle(currentMapStyle)
        .mapControls {
            MapCompass()
            MapScaleView()
            MapPitchToggle()
        }
        .ignoresSafeArea()
    }

    private var currentMapStyle: MapStyle {
        switch appState.selectedMapType {
        case .standard:
            if appState.showPOILayer {
                return .standard(elevation: .realistic)
            } else {
                return .standard(elevation: .realistic, pointsOfInterest: .excludingAll)
            }
        case .satellite:
            return .imagery(elevation: .realistic)
        case .hybrid:
            if appState.showPOILayer {
                return .hybrid(elevation: .realistic)
            } else {
                return .hybrid(elevation: .realistic, pointsOfInterest: .excludingAll)
            }
        case .hybridFlyover:
            if appState.showPOILayer {
                return .hybrid(elevation: .realistic)
            } else {
                return .hybrid(elevation: .realistic, pointsOfInterest: .excludingAll)
            }
        case .mutedStandard:
            return .standard(elevation: .flat, pointsOfInterest: .excludingAll)
        }
    }

    private func rangeRadius(for vehicle: Vehicle) -> CLLocationDistance {
        let rangeMiles = vehicle.batteryRange
        return rangeMiles * 1609.34
    }

    private func rangeColor(for vehicle: Vehicle) -> Color {
        if vehicle.batteryLevel > 50 { return .green }
        if vehicle.batteryLevel > 20 { return .yellow }
        return .red
    }

    private var offlineBanner: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
                .font(.caption.bold())
            Text("No Internet Connection")
                .font(.caption.weight(.medium))
            Spacer()
            Text("Showing cached data")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var navigationBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                .font(.title2)
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                if let dest = navViewModel.selectedDestination {
                    Text(dest.name ?? "Destination")
                        .font(.headline)
                }
                if let route = navViewModel.route {
                    let minutes = Int(route.expectedTravelTime / 60)
                    let miles = route.distance / 1609.34
                    Text("\(minutes) min · \(String(format: "%.1f", miles)) mi")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let est = navViewModel.tripEstimate {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(est.batteryAtDestination)%")
                        .font(.headline)
                        .foregroundStyle(est.batteryAtDestination > 20 ? .green : .red)
                    Text("at arrival")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                navViewModel.stopNavigation()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 16))
        .padding(.horizontal, 12)
        .padding(.top, appState.isOffline ? 8 : 60)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func weatherCard(_ weather: WeatherInfo) -> some View {
        HStack(spacing: 10) {
            Image(systemName: weather.conditionIcon)
                .font(.title2)
                .foregroundStyle(.yellow)
            VStack(alignment: .leading, spacing: 2) {
                Text(weather.locationName)
                    .font(.caption.weight(.semibold))
                Text("\(Int(weather.temperature))°F · \(weather.condition)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 4) {
                ForEach(weather.hourlyForecast.prefix(3)) { h in
                    VStack(spacing: 2) {
                        Text(h.hour)
                            .font(.system(size: 8))
                        Image(systemName: h.icon)
                            .font(.system(size: 10))
                        Text("\(Int(h.temp))°")
                            .font(.system(size: 8))
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(.rect(cornerRadius: 12))
        .frame(maxWidth: 280, alignment: .leading)
    }

    private var bottomSheetContent: some View {
        NavigationStack {
            VStack(spacing: 0) {
                sheetTabBar

                TabView(selection: $appState.selectedTab) {
                    NavigateTabView(viewModel: navViewModel, locationService: locationService, appState: appState)
                        .tag(AppTab.navigate)

                    EnergyTabView(viewModel: energyViewModel, vehicle: appState.selectedVehicle, appState: appState)
                        .tag(AppTab.energy)

                    RoutinesTabView(viewModel: routinesViewModel, appState: appState)
                        .tag(AppTab.routines)

                    VehicleTabView(viewModel: vehicleViewModel, vehicle: appState.selectedVehicle, appState: appState)
                        .tag(AppTab.vehicle)

                    CommunityTabView(viewModel: communityViewModel, locationService: locationService, appState: appState)
                        .tag(AppTab.community)

                    ProfileTabView(appState: appState)
                        .tag(AppTab.profile)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            .navigationBarHidden(true)
        }
    }

    private var sheetTabBar: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 6) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.snappy) {
                            appState.selectedTab = tab
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.subheadline)
                            Text(tab.title)
                                .font(.subheadline.weight(.medium))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(appState.selectedTab == tab ? Color.blue : Color(.tertiarySystemFill))
                        .foregroundStyle(appState.selectedTab == tab ? .white : .primary)
                        .clipShape(Capsule())
                    }
                    .sensoryFeedback(.selection, trigger: appState.selectedTab)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .scrollIndicators(.hidden)
    }

    private func mapButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)
                .frame(width: 40, height: 40)
                .background(.ultraThinMaterial)
                .clipShape(Circle())
        }
        .sensoryFeedback(.impact(weight: .light), trigger: icon)
    }

    private func routineActiveBanner(_ routine: Routine) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Image(systemName: routine.icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .symbolEffect(.bounce, value: routine.id)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Routine Active")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                    Text(routine.name)
                        .font(.headline)
                }

                Spacer()

                ProgressView()
            }
            .padding(16)
            .background(.ultraThinMaterial)
            .clipShape(.rect(cornerRadius: 16))
            .padding(.horizontal, 16)
            .padding(.bottom, 100)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.spring, value: routinesViewModel.activeRoutine?.id)
    }

    private func loadWeather() {
        Task {
            guard let coord = locationService.location?.coordinate else { return }
            appState.weatherInfo = await WeatherService.shared.fetchWeather(for: coord)
        }
    }
}

struct VehiclePinView: View {
    let vehicle: Vehicle

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 36, height: 36)
                Image(systemName: "car.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            Text("\(vehicle.batteryLevel)%")
                .font(.system(size: 9, weight: .bold))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
    }
}

struct SuperchargerMapPin: View {
    let charger: Supercharger

    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(pinColor)
                    .frame(width: 32, height: 32)
                Image(systemName: "bolt.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            Text("\(charger.availableStalls)/\(charger.totalStalls)")
                .font(.system(size: 9, weight: .bold))
                .padding(.horizontal, 4)
                .padding(.vertical, 1)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
        }
    }

    private var pinColor: Color {
        switch charger.availabilityColor {
        case "green": return .green
        case "yellow": return .yellow
        default: return .red
        }
    }
}

struct ReportMapPin: View {
    let report: CommunityReport

    var body: some View {
        Image(systemName: report.type.icon)
            .font(.caption.bold())
            .foregroundStyle(.white)
            .frame(width: 26, height: 26)
            .background(.orange)
            .clipShape(Circle())
    }
}

struct MapTypePickerSheet: View {
    let appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(MapType.allCases, id: \.self) { type in
                    Button {
                        appState.setMapType(type)
                        dismiss()
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: type.icon)
                                .font(.title3)
                                .foregroundStyle(.blue)
                                .frame(width: 32)
                            Text(type.rawValue)
                                .foregroundStyle(.primary)
                            Spacer()
                            if appState.selectedMapType == type {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }

                Section {
                    Toggle("Show Points of Interest", isOn: Binding(
                        get: { appState.showPOILayer },
                        set: { appState.showPOILayer = $0 }
                    ))
                }
            }
            .navigationTitle("Map Style")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct SuperchargerDetailSheet: View {
    let charger: Supercharger
    let navViewModel: NavigationViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(availColor)
                                .frame(width: 48, height: 48)
                            Image(systemName: "bolt.fill")
                                .font(.title3.bold())
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(charger.name)
                                .font(.headline)
                            Text(charger.address.isEmpty ? "Tesla Supercharger" : charger.address)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    HStack(spacing: 16) {
                        StatCard(title: "Available", value: "\(charger.availableStalls)/\(charger.totalStalls)", color: availColor)
                        StatCard(title: "Max Power", value: "\(charger.maxPowerKW) kW", color: .blue)
                        if let price = charger.pricePerKWh {
                            StatCard(title: "Price", value: "$\(String(format: "%.2f", price))/kWh", color: .green)
                        }
                        if let wait = charger.estimatedWaitMinutes {
                            StatCard(title: "Wait", value: "\(wait) min", color: .orange)
                        }
                    }

                    if !charger.amenities.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amenities")
                                .font(.subheadline.weight(.semibold))
                            HStack(spacing: 8) {
                                ForEach(charger.amenities, id: \.self) { amenity in
                                    Label(amenity.rawValue.capitalized, systemImage: amenityIcon(amenity))
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color(.tertiarySystemFill))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    }

                    Button {
                        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: charger.coordinate))
                        mapItem.name = charger.name
                        Task { await navViewModel.calculateRoute(to: mapItem) }
                        dismiss()
                    } label: {
                        Text("Navigate Here")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(16)
            }
            .navigationTitle("Supercharger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private var availColor: Color {
        switch charger.availabilityColor {
        case "green": return .green
        case "yellow": return .yellow
        default: return .red
        }
    }

    private func amenityIcon(_ amenity: ChargerAmenity) -> String {
        switch amenity {
        case .restrooms: return "figure.and.child.holdinghands"
        case .food: return "fork.knife"
        case .wifi: return "wifi"
        case .shopping: return "bag.fill"
        case .lodging: return "bed.double.fill"
        case .park: return "leaf.fill"
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(color)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 10))
    }
}
