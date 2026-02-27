import SwiftUI

struct ContentView: View {
    @State private var batteryLevel: Int = 78
    @State private var isLocked: Bool = true
    @State private var isClimateOn: Bool = false
    @State private var range: Double = 245
    @State private var isCharging: Bool = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    batteryCard
                    controlsGrid
                    statusCard
                }
                .padding(.horizontal, 4)
            }
            .navigationTitle("Tellsla")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var batteryCard: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .stroke(Color(.darkGray), lineWidth: 6)
                    .frame(width: 70, height: 70)
                Circle()
                    .trim(from: 0, to: Double(batteryLevel) / 100.0)
                    .stroke(batteryColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(batteryLevel)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text("%")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
            }

            Text("\(Int(range)) mi")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if isCharging {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.green)
                    Text("Charging")
                        .font(.system(size: 10))
                        .foregroundStyle(.green)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private var controlsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            WatchControlButton(
                icon: isLocked ? "lock.fill" : "lock.open.fill",
                label: isLocked ? "Unlock" : "Lock",
                color: .blue
            ) {
                isLocked.toggle()
            }

            WatchControlButton(
                icon: isClimateOn ? "snowflake" : "thermometer.medium",
                label: "Climate",
                color: isClimateOn ? .cyan : .orange
            ) {
                isClimateOn.toggle()
            }

            WatchControlButton(
                icon: "lightbulb.fill",
                label: "Flash",
                color: .yellow
            ) {}

            WatchControlButton(
                icon: "speaker.wave.3.fill",
                label: "Horn",
                color: .purple
            ) {}
        }
    }

    private var statusCard: some View {
        VStack(spacing: 6) {
            HStack {
                Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                    .font(.caption2)
                    .foregroundStyle(isLocked ? .green : .orange)
                Text(isLocked ? "Locked" : "Unlocked")
                    .font(.caption2)
                Spacer()
            }
            HStack {
                Image(systemName: "thermometer")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("72°F Interior")
                    .font(.caption2)
                Spacer()
            }
        }
        .padding(8)
        .background(Color(.darkGray).opacity(0.3))
        .clipShape(.rect(cornerRadius: 10))
    }

    private var batteryColor: Color {
        if batteryLevel > 60 { return .green }
        if batteryLevel > 20 { return .yellow }
        return .red
    }
}

struct WatchControlButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 10))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(color.opacity(0.15))
            .clipShape(.rect(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }
}
