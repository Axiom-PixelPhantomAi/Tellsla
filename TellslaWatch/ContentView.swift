import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @State private var vehicle: Vehicle?
    @State private var isLoading = true
    @State private var batteryLevel = 0
    @State private var range = 0
    @State private var isCharging = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Battery Ring
                VStack {
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemFill), lineWidth: 6)
                        
                        Circle()
                            .trim(from: 0, to: Double(batteryLevel) / 100)
                            .stroke(batteryColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 2) {
                            Text("\(batteryLevel)")
                                .font(.system(size: 22, weight: .bold))
                            Text("%")
                                .font(.caption)
                        }
                    }
                    .frame(width: 80, height: 80)
                    
                    Text("\(range) mi")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(10)
                
                // Quick Actions
                VStack(spacing: 10) {
                    NavigationLink(destination: LockedView()) {
                        HStack {
                            Image(systemName: "lock.fill")
                            Text("Lock")
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                    }
                    
                    NavigationLink(destination: ClimateView()) {
                        HStack {
                            Image(systemName: isCharging ? "bolt.fill" : "thermometer.half")
                            Text(isCharging ? "Charging" : "Climate")
                            Spacer()
                        }
                        .padding(10)
                        .background(isCharging ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                        .cornerRadius(8)
                    }
                    
                    NavigationLink(destination: FindMyTeslaView()) {
                        HStack {
                            Image(systemName: "location.fill")
                            Text("Find My Tesla")
                            Spacer()
                        }
                        .padding(10)
                        .background(Color.purple.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Tesla")
        }
        .onAppear {
            loadVehicleData()
        }
    }
    
    private var batteryColor: Color {
        if batteryLevel > 50 { return .green }
        if batteryLevel > 20 { return .yellow }
        return .red
    }
    
    private func loadVehicleData() {
        Task {
            do {
                let vehicles = try await TeslaAPIService.shared.fetchVehicles()
                if let vehicle = vehicles.first {
                    await MainActor.run {
                        self.vehicle = vehicle
                        self.batteryLevel = vehicle.batteryLevel
                        self.range = Int(vehicle.batteryRange)
                        self.isCharging = vehicle.chargingState == .charging
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                }
            }
        }
    }
}

// MARK: - Lock View
struct LockedView: View {
    @State private var isLocked = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text(isLocked ? "🔒 Locked" : "🔓 Unlocked")
                .font(.headline)
            
            Button {
                Task {
                    // Placeholder for lock command
                    isLocked.toggle()
                }
            } label: {
                Text(isLocked ? "Unlock" : "Lock")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button("Back") { dismiss() }
        }
        .padding()
    }
}

// MARK: - Climate View
struct ClimateView: View {
    @State private var temperature = 72
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Climate Control")
                .font(.headline)
            
            HStack {
                Button { temperature = max(60, temperature - 1) } label: {
                    Image(systemName: "minus.circle.fill")
                }
                Text("\(temperature)°F")
                    .font(.title3.bold())
                Button { temperature = min(90, temperature + 1) } label: {
                    Image(systemName: "plus.circle.fill")
                }
            }
            
            Button("Start Climate") {
                Task {
                    // Placeholder for climate command
                }
            }
            .buttonStyle(.bordered)
            
            Button("Back") { dismiss() }
        }
        .padding()
    }
}

// MARK: - Find My Tesla View
struct FindMyTeslaView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("📍 Find My Tesla")
                .font(.headline)
            
            VStack(spacing: 8) {
                Text("0.3 mi East")
                    .font(.subheadline)
                Text("↗ Northeast")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Button("Back") { dismiss() }
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
