import WidgetKit
import SwiftUI

struct TeslaEntry: TimelineEntry {
    let date: Date
    let batteryLevel: Int
    let range: Double
    let isCharging: Bool
    let isClimateOn: Bool
    let isLocked: Bool
    let vehicleName: String
}

struct TeslaProvider: TimelineProvider {
    func placeholder(in context: Context) -> TeslaEntry {
        TeslaEntry(date: .now, batteryLevel: 78, range: 245, isCharging: false, isClimateOn: false, isLocked: true, vehicleName: "My Tesla")
    }

    func getSnapshot(in context: Context, completion: @escaping (TeslaEntry) -> Void) {
        completion(TeslaEntry(date: .now, batteryLevel: 78, range: 245, isCharging: false, isClimateOn: false, isLocked: true, vehicleName: "My Tesla"))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TeslaEntry>) -> Void) {
        let entry = TeslaEntry(date: .now, batteryLevel: 78, range: 245, isCharging: false, isClimateOn: false, isLocked: true, vehicleName: "My Tesla")
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct TellslaWidgetSmall: View {
    let entry: TeslaEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bolt.car.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text(entry.vehicleName)
                    .font(.caption2.weight(.semibold))
                    .lineLimit(1)
                Spacer()
            }

            ZStack {
                Circle()
                    .stroke(Color(.systemGray4), lineWidth: 5)
                    .frame(width: 52, height: 52)
                Circle()
                    .trim(from: 0, to: Double(entry.batteryLevel) / 100.0)
                    .stroke(batteryColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 52, height: 52)
                    .rotationEffect(.degrees(-90))
                Text("\(entry.batteryLevel)%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .frame(maxWidth: .infinity)

            HStack(spacing: 4) {
                Image(systemName: "road.lanes")
                    .font(.system(size: 8))
                Text("\(Int(entry.range)) mi")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                Image(systemName: entry.isLocked ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(entry.isLocked ? .green : .orange)
                if entry.isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(.green)
                }
                if entry.isClimateOn {
                    Image(systemName: "snowflake")
                        .font(.system(size: 9))
                        .foregroundStyle(.cyan)
                }
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var batteryColor: Color {
        if entry.batteryLevel > 60 { return .green }
        if entry.batteryLevel > 20 { return .yellow }
        return .red
    }
}

struct TellslaWidgetMedium: View {
    let entry: TeslaEntry

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.car.fill")
                        .foregroundStyle(.blue)
                    Text(entry.vehicleName)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                }

                ZStack {
                    Circle()
                        .stroke(Color(.systemGray4), lineWidth: 6)
                        .frame(width: 64, height: 64)
                    Circle()
                        .trim(from: 0, to: Double(entry.batteryLevel) / 100.0)
                        .stroke(batteryColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 64, height: 64)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("\(entry.batteryLevel)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text("%")
                            .font(.system(size: 9))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }

            VStack(alignment: .leading, spacing: 10) {
                StatusRow(icon: "road.lanes", label: "Range", value: "\(Int(entry.range)) mi")
                StatusRow(icon: entry.isLocked ? "lock.fill" : "lock.open.fill", label: "Doors", value: entry.isLocked ? "Locked" : "Unlocked")
                StatusRow(icon: entry.isCharging ? "bolt.fill" : "bolt.slash", label: "Charging", value: entry.isCharging ? "Active" : "Off")
                StatusRow(icon: entry.isClimateOn ? "snowflake" : "thermometer", label: "Climate", value: entry.isClimateOn ? "On" : "Off")
            }
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var batteryColor: Color {
        if entry.batteryLevel > 60 { return .green }
        if entry.batteryLevel > 20 { return .yellow }
        return .red
    }
}

struct StatusRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
                .frame(width: 14)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption2.weight(.medium))
        }
    }
}

struct TellslaWidget: Widget {
    let kind: String = "TellslaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TeslaProvider()) { entry in
            if #available(iOSApplicationExtension 17.0, *) {
                TellslaWidgetContainer(entry: entry)
            }
        }
        .configurationDisplayName("Tesla Status")
        .description("Battery, charging, and vehicle status at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@available(iOSApplicationExtension 17.0, *)
struct TellslaWidgetContainer: View {
    let entry: TeslaEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            TellslaWidgetSmall(entry: entry)
        case .systemMedium:
            TellslaWidgetMedium(entry: entry)
        default:
            TellslaWidgetSmall(entry: entry)
        }
    }
}
