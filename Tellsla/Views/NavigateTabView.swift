import SwiftUI
import MapKit

struct NavigateTabView: View {
    @Bindable var viewModel: NavigationViewModel
    let locationService: LocationService
    let appState: AppState
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                searchBar

                if !searchText.isEmpty && !viewModel.searchResults.isEmpty {
                    searchResultsList
                } else if searchText.isEmpty {
                    quickActions
                    superchargerSection
                    recentSection
                }

                if let estimate = viewModel.tripEstimate {
                    tripEstimateCard(estimate)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Search destination", text: $searchText)
                .focused($isSearchFocused)
                .submitLabel(.search)
                .onSubmit {
                    Task { await viewModel.search(searchText) }
                }
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    viewModel.searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.tertiarySystemFill))
        .clipShape(.rect(cornerRadius: 12))
        .onChange(of: searchText) { _, newValue in
            Task { await viewModel.search(newValue) }
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Launch")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(viewModel.quickDestinations) { dest in
                    Button {
                        if dest.id == "charger" {
                            Task { await viewModel.loadNearbySuperchargers() }
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: dest.icon)
                                .font(.title2)
                                .foregroundStyle(.blue)
                                .frame(width: 48, height: 48)
                                .background(Color.blue.opacity(0.12))
                                .clipShape(Circle())
                            Text(dest.name)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(dest.subtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private var superchargerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Nearby Superchargers")
                    .font(.headline)
                Spacer()
                Button {
                    appState.showTutorial = true
                    appState.tutorialSection = "navigate"
                } label: {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.superchargers.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "bolt.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("Connect your Tesla account to see nearby Superchargers with live availability.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))
            } else {
                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.superchargers.prefix(5)) { charger in
                            SuperchargerCard(charger: charger) {
                                let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: charger.coordinate))
                                mapItem.name = charger.name
                                Task { await viewModel.calculateRoute(to: mapItem) }
                            }
                        }
                    }
                }
                .contentMargins(.horizontal, 0)
                .scrollIndicators(.hidden)
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.recentDestinations.isEmpty {
                Text("Recent")
                    .font(.headline)

                ForEach(viewModel.recentDestinations.prefix(5)) { recent in
                    Button {
                        let coord = CLLocationCoordinate2D(latitude: recent.latitude, longitude: recent.longitude)
                        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coord))
                        mapItem.name = recent.name
                        Task { await viewModel.calculateRoute(to: mapItem) }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "clock.fill")
                                .foregroundStyle(.secondary)
                                .frame(width: 32, height: 32)
                                .background(Color(.tertiarySystemFill))
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 2) {
                                Text(recent.name)
                                    .font(.subheadline.weight(.medium))
                                    .foregroundStyle(.primary)
                                Text(recent.address)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                    }
                }
            }
        }
    }

    private var searchResultsList: some View {
        VStack(spacing: 2) {
            ForEach(viewModel.searchResults, id: \.self) { item in
                Button {
                    Task {
                        await viewModel.calculateRoute(to: item)
                        searchText = ""
                        isSearchFocused = false
                        viewModel.searchResults = []
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundStyle(.red)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name ?? "Unknown")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.primary)
                            Text(item.placemark.title ?? "")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Image(systemName: "arrow.turn.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 10)
                }
            }
        }
    }

    private func tripEstimateCard(_ estimate: TripEnergyEstimate) -> some View {
        VStack(spacing: 14) {
            HStack {
                Text("Trip Estimate")
                    .font(.headline)
                Spacer()
                Button {
                    viewModel.startNavigation()
                } label: {
                    Text("Start")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
            }

            HStack(spacing: 16) {
                TripMetric(title: "Distance", value: String(format: "%.1f mi", estimate.distanceMiles), icon: "road.lanes")
                TripMetric(title: "Energy", value: String(format: "%.1f kWh", estimate.estimatedKWh), icon: "bolt.fill")
                TripMetric(title: "Cost", value: String(format: "$%.2f", estimate.estimatedCost), icon: "dollarsign.circle")
                TripMetric(title: "Arrival", value: "\(estimate.batteryAtDestination)%", icon: "battery.50percent")
            }

            if estimate.needsCharging {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                    Text("Charging stop recommended")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(10)
                .background(Color.yellow.opacity(0.1))
                .clipShape(.rect(cornerRadius: 8))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 16))
    }
}

struct TripMetric: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SuperchargerCard: View {
    let charger: Supercharger
    let onNavigate: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(availColor)
                Text(charger.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(charger.availableStalls)/\(charger.totalStalls)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(availColor)
                    Text("Available")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(charger.maxPowerKW) kW")
                        .font(.subheadline.weight(.semibold))
                    Text("Max Power")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if let price = charger.pricePerKWh {
                Text("$\(String(format: "%.2f", price))/kWh")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("Navigate", action: onNavigate)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
        }
        .padding(12)
        .frame(width: 180)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private var availColor: Color {
        switch charger.availabilityColor {
        case "green": return .green
        case "yellow": return .yellow
        default: return .red
        }
    }
}
