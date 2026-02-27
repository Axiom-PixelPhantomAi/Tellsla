import SwiftUI

struct VehicleTabView: View {
    @Bindable var viewModel: VehicleViewModel
    let vehicle: Vehicle?
    let appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                vehicleHeader
                quickControls
                sentryEventFeed
                tirePressureGrid
                diagnosticsSection
                driveProfilesSection
                preTripChecklist
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
        }
        .scrollIndicators(.hidden)
        .alert("Command", isPresented: $viewModel.showCommandConfirmation) {
            Button("OK") {}
        } message: {
            Text(viewModel.lastCommandResult ?? "")
        }
    }

    private var vehicleHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: "car.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(vehicle?.displayName ?? "My Tesla")
                    .font(.title3.bold())
                Text(vehicle?.model.rawValue ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 8) {
                    Label(vehicle?.isLocked == true ? "Locked" : "Unlocked",
                          systemImage: vehicle?.isLocked == true ? "lock.fill" : "lock.open.fill")
                        .font(.caption)
                        .foregroundStyle(vehicle?.isLocked == true ? .green : .orange)
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text(vehicle?.softwareVersion ?? "—")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()

            Button {
                appState.showTutorial = true
                appState.tutorialSection = "vehicle"
            } label: {
                Image(systemName: "questionmark.circle")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var quickControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Controls")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                VehicleControlButton(icon: vehicle?.isLocked == true ? "lock.fill" : "lock.open.fill",
                                     label: vehicle?.isLocked == true ? "Unlock" : "Lock",
                                     color: .blue,
                                     isLoading: viewModel.isLocking) {
                    guard let v = vehicle else { return }
                    Task {
                        if v.isLocked {
                            await viewModel.unlockVehicle(v)
                        } else {
                            await viewModel.lockVehicle(v)
                        }
                    }
                }

                VehicleControlButton(icon: vehicle?.isClimateOn == true ? "snowflake" : "thermometer.medium",
                                     label: "Climate",
                                     color: vehicle?.isClimateOn == true ? .cyan : .orange,
                                     isLoading: viewModel.isTogglingClimate) {
                    guard let v = vehicle else { return }
                    Task { await viewModel.toggleClimate(v) }
                }

                VehicleControlButton(icon: "eye.fill",
                                     label: "Sentry",
                                     color: vehicle?.sentryModeActive == true ? .green : .secondary,
                                     isLoading: viewModel.isToggingSentry) {
                    guard let v = vehicle else { return }
                    Task { await viewModel.toggleSentry(v) }
                }

                VehicleControlButton(icon: "lightbulb.fill",
                                     label: "Flash",
                                     color: .yellow,
                                     isLoading: false) {
                    guard let v = vehicle else { return }
                    Task { await viewModel.flashLights(v) }
                }

                VehicleControlButton(icon: "speaker.wave.3.fill",
                                     label: "Horn",
                                     color: .purple,
                                     isLoading: false) {
                    guard let v = vehicle else { return }
                    Task { await viewModel.honkHorn(v) }
                }

                VehicleControlButton(icon: "car.top.door.front.left.open",
                                     label: "Frunk",
                                     color: .teal,
                                     isLoading: false) {
                    guard let v = vehicle else { return }
                    Task { await viewModel.openFrunk(v) }
                }

                VehicleControlButton(icon: "shippingbox.fill",
                                     label: "Trunk",
                                     color: .indigo,
                                     isLoading: false) {
                    guard let v = vehicle else { return }
                    Task { await viewModel.openTrunk(v) }
                }

                VehicleControlButton(icon: "bolt.fill",
                                     label: "Charge",
                                     color: .green,
                                     isLoading: false) {}
            }
        }
    }

    private var sentryEventFeed: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sentry Events")
                    .font(.headline)
                Spacer()
                Button {
                    appState.showTutorial = true
                    appState.tutorialSection = "sentry"
                } label: {
                    Text("How it works")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }

            if viewModel.sentryEvents.isEmpty {
                HStack(spacing: 14) {
                    Image(systemName: "eye.trianglebadge.exclamationmark")
                        .font(.title2)
                        .foregroundStyle(.green)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI-Filtered Events")
                            .font(.subheadline.weight(.medium))
                        Text("No sentry events detected. Smart Sentry filters false alarms using computer vision.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))
            } else {
                ForEach(viewModel.sentryEvents.prefix(5)) { event in
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.tertiarySystemFill))
                                .frame(width: 44, height: 44)
                            Image(systemName: sentryIcon(event.type))
                                .font(.body)
                                .foregroundStyle(event.isVerifiedThreat ? .red : .secondary)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(event.type.rawValue.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression).capitalized)
                                    .font(.subheadline.weight(.medium))
                                if event.isVerifiedThreat {
                                    Text("THREAT")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(Color.red.opacity(0.15))
                                        .foregroundStyle(.red)
                                        .clipShape(Capsule())
                                }
                            }
                            Text(event.timestamp.formatted(.relative(presentation: .named)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(event.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                    }
                    .padding(10)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 10))
                }
            }

            HStack {
                VStack(spacing: 2) {
                    Text("\(viewModel.sentryEvents.count)")
                        .font(.title2.bold())
                    Text("Events")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text("\(viewModel.sentryEvents.filter(\.isVerifiedThreat).count)")
                        .font(.title2.bold())
                        .foregroundStyle(.red)
                    Text("Threats")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    Text("\(viewModel.sentryEvents.filter { !$0.isVerifiedThreat }.count)")
                        .font(.title2.bold())
                        .foregroundStyle(.green)
                    Text("Filtered")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 10))
        }
    }

    private var tirePressureGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tire Pressure")
                .font(.headline)

            let pressures = vehicle?.tirePressures ?? TirePressures(frontLeft: 0, frontRight: 0, rearLeft: 0, rearRight: 0)

            VStack(spacing: 16) {
                HStack(spacing: 24) {
                    TirePressureCell(label: "FL", psi: pressures.frontLeft, status: pressures.status(for: pressures.frontLeft))
                    TirePressureCell(label: "FR", psi: pressures.frontRight, status: pressures.status(for: pressures.frontRight))
                }
                HStack(spacing: 24) {
                    TirePressureCell(label: "RL", psi: pressures.rearLeft, status: pressures.status(for: pressures.rearLeft))
                    TirePressureCell(label: "RR", psi: pressures.rearRight, status: pressures.status(for: pressures.rearRight))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 16))
        }
    }

    private var diagnosticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Diagnostics")
                .font(.headline)

            VStack(spacing: 10) {
                DiagnosticRow(label: "Odometer", value: String(format: "%.0f mi", vehicle?.odometer ?? 0), icon: "gauge.with.dots.needle.50percent")
                DiagnosticRow(label: "Interior", value: String(format: "%.0f°F", (vehicle?.interiorTemp ?? 20) * 9/5 + 32), icon: "thermometer")
                DiagnosticRow(label: "Exterior", value: String(format: "%.0f°F", (vehicle?.exteriorTemp ?? 20) * 9/5 + 32), icon: "sun.max.fill")
                DiagnosticRow(label: "12V Battery", value: "OK", icon: "battery.100percent")
                DiagnosticRow(label: "HVAC Filter", value: "Good", icon: "aqi.medium")
                DiagnosticRow(label: "Last Seen", value: vehicle?.lastSeen.formatted(.relative(presentation: .named)) ?? "—", icon: "clock")
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private var driveProfilesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Drive Profiles")
                .font(.headline)

            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    DriveProfileCard(name: "Sport", icon: "hare.fill", color: .red, isActive: false)
                    DriveProfileCard(name: "Efficiency", icon: "leaf.fill", color: .green, isActive: true)
                    DriveProfileCard(name: "Comfort", icon: "sofa.fill", color: .blue, isActive: false)
                }
            }
            .contentMargins(.horizontal, 0)
            .scrollIndicators(.hidden)
        }
    }

    private var preTripChecklist: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Pre-Trip Check")
                .font(.headline)

            VStack(spacing: 8) {
                ChecklistItem(title: "Battery", value: "\(vehicle?.batteryLevel ?? 0)%", status: (vehicle?.batteryLevel ?? 0) > 50 ? .good : .warning)
                ChecklistItem(title: "Tire Pressure", value: "All Normal", status: .good)
                ChecklistItem(title: "Climate", value: vehicle?.isClimateOn == true ? "On" : "Off", status: .info)
                ChecklistItem(title: "Sentry Mode", value: vehicle?.sentryModeActive == true ? "Active" : "Off", status: .info)
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    private func sentryIcon(_ type: SentryEventType) -> String {
        switch type {
        case .personApproaching: return "figure.walk"
        case .vehicleTouch: return "hand.raised.fill"
        case .collision: return "car.2.fill"
        case .weather: return "cloud.rain.fill"
        case .animal: return "pawprint.fill"
        case .unknown: return "questionmark.circle"
        }
    }
}

struct VehicleControlButton: View {
    let icon: String
    let label: String
    let color: Color
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    if isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundStyle(color)
                    }
                }
                .frame(width: 44, height: 44)
                .background(color.opacity(0.12))
                .clipShape(.rect(cornerRadius: 12))

                Text(label)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
        }
        .disabled(isLoading)
        .sensoryFeedback(.impact(weight: .medium), trigger: isLoading)
    }
}

struct TirePressureCell: View {
    let label: String
    let psi: Double
    let status: TirePressureStatus

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(String(format: "%.0f", psi))
                .font(.title2.bold())
                .foregroundStyle(statusColor)
            Text("PSI")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var statusColor: Color {
        switch status {
        case .low: return .red
        case .normal: return .green
        case .high: return .orange
        }
    }
}

struct DiagnosticRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }
}

struct DriveProfileCard: View {
    let name: String
    let icon: String
    let color: Color
    let isActive: Bool

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isActive ? .white : color)
                .frame(width: 48, height: 48)
                .background(isActive ? color : color.opacity(0.12))
                .clipShape(Circle())
            Text(name)
                .font(.caption.weight(.medium))
                .foregroundStyle(isActive ? color : .primary)
        }
        .frame(width: 80)
        .padding(.vertical, 12)
        .background(isActive ? color.opacity(0.08) : Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .overlay {
            if isActive {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            }
        }
    }
}

struct ChecklistItem: View {
    let title: String
    let value: String
    let status: CheckStatus

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var statusColor: Color {
        switch status {
        case .good: return .green
        case .warning: return .yellow
        case .critical: return .red
        case .info: return .blue
        }
    }
}

nonisolated enum CheckStatus: Sendable {
    case good, warning, critical, info
}
