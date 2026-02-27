import SwiftUI
import Charts

struct EnergyTabView: View {
    @Bindable var viewModel: EnergyViewModel
    let vehicle: Vehicle?
    let appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                batterySection
                smartChargingTip
                chargingHistoryChart
                solarSection
                pricingSection
                batteryHealthSection
                fleetSection
                maintenanceSection
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
        .scrollIndicators(.hidden)
    }

    private var batterySection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Battery Status")
                    .font(.headline)
                Spacer()
                Button {
                    appState.showTutorial = true
                    appState.tutorialSection = "energy"
                } label: {
                    Image(systemName: "questionmark.circle")
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color(.tertiarySystemFill), lineWidth: 10)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: Double(vehicle?.batteryLevel ?? 0) / 100.0)
                        .stroke(
                            batteryColor,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.spring(response: 0.8), value: vehicle?.batteryLevel)

                    VStack(spacing: 0) {
                        Text("\(vehicle?.batteryLevel ?? 0)")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("%")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    EnergyStatRow(label: "Range", value: String(format: "%.0f mi", vehicle?.batteryRange ?? 0), icon: "road.lanes")
                    EnergyStatRow(label: "Charge Limit", value: "\(vehicle?.chargeLimit ?? 80)%", icon: "battery.75percent")
                    EnergyStatRow(label: "State", value: vehicle?.chargingState.rawValue ?? "—", icon: "bolt.fill")
                }
            }
            .padding(16)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 16))
        }
    }

    @ViewBuilder
    private var smartChargingTip: some View {
        if viewModel.showSmartChargingTip {
            HStack(spacing: 12) {
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
                    .foregroundStyle(.yellow)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Smart Charging Tip")
                        .font(.subheadline.weight(.semibold))
                    Text("Connect your Tesla account to get personalized charging recommendations based on your electricity rates and solar production.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Button {
                    viewModel.dismissSmartChargingTip()
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .background(Color.yellow.opacity(0.08))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var chargingHistoryChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Charging History")
                    .font(.headline)
                Spacer()
                Picker("Range", selection: $viewModel.selectedTimeRange) {
                    ForEach(EnergyTimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            if viewModel.chargingSessions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title)
                        .foregroundStyle(.secondary)
                    Text("No charging data yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))
            } else {
                Chart(viewModel.chargingSessions) { session in
                    BarMark(
                        x: .value("Date", session.date, unit: .day),
                        y: .value("kWh", session.kWhAdded)
                    )
                    .foregroundStyle(chargerColor(session.chargerType))
                    .clipShape(.rect(cornerRadius: 4))
                }
                .frame(height: 160)
                .chartYAxisLabel("kWh")
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))

                HStack(spacing: 16) {
                    ChargingStat(title: "Sessions", value: "\(viewModel.chargingSessions.count)", icon: "bolt.fill")
                    ChargingStat(title: "Total kWh", value: String(format: "%.0f", viewModel.chargingSessions.reduce(0) { $0 + $1.kWhAdded }), icon: "battery.100percent")
                    ChargingStat(title: "Total Cost", value: String(format: "$%.0f", viewModel.chargingSessions.reduce(0) { $0 + $1.cost }), icon: "dollarsign.circle")
                }
            }
        }
    }

    private var solarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Solar Integration")
                .font(.headline)

            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    Image(systemName: "sun.max.fill")
                        .font(.title2)
                        .foregroundStyle(.orange)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Solar Production")
                            .font(.subheadline.weight(.medium))
                        Text("Connect a Powerwall or solar system to see real-time production and optimize charging around peak solar hours.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 14) {
                    Image(systemName: "clock.arrow.2.circlepath")
                        .font(.title2)
                        .foregroundStyle(.green)
                        .frame(width: 40)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time-of-Use Optimization")
                            .font(.subheadline.weight(.medium))
                        Text("Automatically schedules charging during off-peak hours. Potential savings of up to 60% on charging costs.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Electricity Pricing")
                .font(.headline)

            HStack(spacing: 12) {
                PricingCard(title: "Off-Peak", price: "$0.08", subtitle: "12am–6am", color: .green, isActive: true)
                PricingCard(title: "Mid-Peak", price: "$0.15", subtitle: "6am–4pm", color: .yellow, isActive: false)
                PricingCard(title: "Peak", price: "$0.32", subtitle: "4pm–9pm", color: .red, isActive: false)
            }
        }
    }

    private var batteryHealthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Battery Health")
                .font(.headline)

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estimated Capacity")
                            .font(.subheadline.weight(.medium))
                        Text("Based on charging patterns and driving data")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("96%")
                            .font(.title2.bold())
                            .foregroundStyle(.green)
                        Text("of original")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                ProgressView(value: 0.96)
                    .tint(.green)

                HStack {
                    Text("Degradation Rate")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("Normal for model/year")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var fleetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Fleet Management")
                    .font(.headline)
                Spacer()
                Button {
                    appState.showTutorial = true
                    appState.tutorialSection = "fleet"
                } label: {
                    Text("Learn More")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            VStack(spacing: 12) {
                Image(systemName: "car.2.fill")
                    .font(.title)
                    .foregroundStyle(.secondary)
                Text("Multi-Vehicle Coordination")
                    .font(.subheadline.weight(.medium))
                Text("Add multiple Teslas to coordinate charging schedules, assign vehicles to trips, and balance electrical load.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var maintenanceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Predictive Maintenance")
                .font(.headline)

            VStack(spacing: 10) {
                MaintenanceRow(component: "Front Tires", condition: 0.72, daysUntil: 45, icon: "circle.circle")
                MaintenanceRow(component: "Rear Tires", condition: 0.65, daysUntil: 30, icon: "circle.circle")
                MaintenanceRow(component: "Cabin Filter", condition: 0.45, daysUntil: 14, icon: "aqi.medium")
                MaintenanceRow(component: "Wiper Blades", condition: 0.30, daysUntil: 7, icon: "wiper.vertical.and.water")
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var batteryColor: Color {
        guard let level = vehicle?.batteryLevel else { return .green }
        if level > 60 { return .green }
        if level > 20 { return .yellow }
        return .red
    }

    private func chargerColor(_ type: ChargerType) -> Color {
        switch type {
        case .home: return .green
        case .supercharger: return .red
        case .thirdParty: return .blue
        }
    }
}

struct EnergyStatRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
        }
    }
}

struct PricingCard: View {
    let title: String
    let price: String
    let subtitle: String
    let color: Color
    let isActive: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(price)
                .font(.headline)
                .foregroundStyle(color)
            Text(title)
                .font(.caption.weight(.medium))
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(isActive ? color.opacity(0.1) : Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 10))
        .overlay {
            if isActive {
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            }
        }
    }
}

struct MaintenanceRow: View {
    let component: String
    let condition: Double
    let daysUntil: Int
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(conditionColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(component)
                    .font(.subheadline.weight(.medium))
                Text("~\(daysUntil) days remaining")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.tertiarySystemFill))
                    .frame(width: 60, height: 6)
                Capsule()
                    .fill(conditionColor)
                    .frame(width: 60 * condition, height: 6)
            }
        }
    }

    private var conditionColor: Color {
        if condition > 0.6 { return .green }
        if condition > 0.3 { return .yellow }
        return .red
    }
}

struct ChargingStat: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
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
