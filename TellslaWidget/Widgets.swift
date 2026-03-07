import WidgetKit
import SwiftUI

// MARK: - Small Widget (Battery + Range)
struct TellslaSmallWidget: Widget {
    let kind: String = "TellslaSmall"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: SmallWidgetProvider()
        ) { entry in
            SmallWidgetView(entry: entry)
        }
        .configurationDisplayName("Tesla Status")
        .description("Battery, range, and climate status at a glance")
        .supportedFamilies([.systemSmall])
    }
}

struct SmallWidgetEntry: TimelineEntry {
    let date: Date
    let batteryLevel: Int
    let range: Int
    let isCharging: Bool
    let climateOn: Bool
}

struct SmallWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> SmallWidgetEntry {
        SmallWidgetEntry(date: Date(), batteryLevel: 75, range: 180, isCharging: false, climateOn: false)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SmallWidgetEntry) -> Void) {
        let entry = SmallWidgetEntry(date: Date(), batteryLevel: 75, range: 180, isCharging: false, climateOn: false)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SmallWidgetEntry>) -> Void) {
        // Widget uses placeholder data - main app provides real data via shared container
        let entry = SmallWidgetEntry(
            date: Date(),
            batteryLevel: 75,
            range: 180,
            isCharging: false,
            climateOn: false
        )
        let nextUpdate = Date().addingTimeInterval(300) // 5 min
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct SmallWidgetView: View {
    let entry: SmallWidgetEntry
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(entry.batteryLevel)%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("Battery")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color(.tertiarySystemFill), lineWidth: 3)
                    Circle()
                        .trim(from: 0, to: Double(entry.batteryLevel) / 100)
                        .stroke(entry.batteryLevel > 50 ? .green : entry.batteryLevel > 20 ? .yellow : .red, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 50, height: 50)
            }
            
            HStack {
                Label("\(entry.range) mi", systemImage: "road.lanes")
                    .font(.caption.weight(.semibold))
                Spacer()
                if entry.isCharging {
                    Label("Charging", systemImage: "bolt.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                }
                if entry.climateOn {
                    Label("Climate", systemImage: "thermometer.half")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }
}

// MARK: - Lock Screen Widget
struct TellslaLockScreenWidget: Widget {
    let kind: String = "TellslaLockScreen"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: LockScreenWidgetProvider()
        ) { entry in
            LockScreenWidgetView(entry: entry)
        }
        .configurationDisplayName("Battery & Charging")
        .description("Quick battery status on lock screen")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

struct LockScreenWidgetEntry: TimelineEntry {
    let date: Date
    let batteryLevel: Int
    let timeToFullCharge: Int? // minutes
    let isCharging: Bool
}

struct LockScreenWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LockScreenWidgetEntry {
        LockScreenWidgetEntry(date: Date(), batteryLevel: 75, timeToFullCharge: 45, isCharging: true)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (LockScreenWidgetEntry) -> Void) {
        let entry = LockScreenWidgetEntry(date: Date(), batteryLevel: 75, timeToFullCharge: 45, isCharging: true)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<LockScreenWidgetEntry>) -> Void) {
        // Widget uses placeholder data - main app provides real data via shared container
        let entry = LockScreenWidgetEntry(
            date: Date(),
            batteryLevel: 75,
            timeToFullCharge: 45,
            isCharging: true
        )
        let nextUpdate = Date().addingTimeInterval(300)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct LockScreenWidgetView: View {
    let entry: LockScreenWidgetEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            VStack(spacing: 4) {
                Text("\(entry.batteryLevel)%")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                
                if let timeToFull = entry.timeToFullCharge, entry.isCharging {
                    Text("\(timeToFull)m")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Dynamic Island Widget
struct TellslaDynamicIslandWidget: Widget {
    let kind: String = "TellslaDynamicIsland"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: DynamicIslandWidgetProvider()
        ) { entry in
            DynamicIslandWidgetView(entry: entry)
        }
        .configurationDisplayName("Live Activity")
        .description("Charging progress in Dynamic Island")
        .supportedFamilies([.systemSmall])
    }
}

struct DynamicIslandEntry: TimelineEntry {
    let date: Date
    let batteryLevel: Int
    let isCharging: Bool
    let timeToFullCharge: Int?
}

struct DynamicIslandWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> DynamicIslandEntry {
        DynamicIslandEntry(date: Date(), batteryLevel: 75, isCharging: true, timeToFullCharge: 45)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (DynamicIslandEntry) -> Void) {
        let entry = DynamicIslandEntry(date: Date(), batteryLevel: 75, isCharging: true, timeToFullCharge: 45)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<DynamicIslandEntry>) -> Void) {
        // Widget uses placeholder data - main app provides real data via shared container
        let entry = DynamicIslandEntry(
            date: Date(),
            batteryLevel: 75,
            isCharging: false,
            timeToFullCharge: 45
        )
        let nextUpdate = Date().addingTimeInterval(300)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }
}

struct DynamicIslandWidgetView: View {
    let entry: DynamicIslandEntry
    
    var body: some View {
        if entry.isCharging {
            HStack(spacing: 8) {
                Image(systemName: "bolt.fill")
                    .foregroundStyle(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Charging")
                        .font(.caption.weight(.semibold))
                    if let time = entry.timeToFullCharge {
                        Text("\(entry.batteryLevel)% • \(time)m")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                ProgressView(value: Double(entry.batteryLevel) / 100)
                    .tint(.green)
            }
            .padding(8)
        } else {
            HStack(spacing: 8) {
                Image(systemName: "car.fill")
                    .foregroundStyle(.blue)
                
                Text("\(entry.batteryLevel)% Battery")
                    .font(.caption.weight(.semibold))
                
                Spacer()
            }
            .padding(8)
        }
    }
}
