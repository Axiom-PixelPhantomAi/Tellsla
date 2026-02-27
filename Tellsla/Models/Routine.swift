import Foundation

nonisolated struct Routine: Codable, Identifiable, Hashable, Sendable {
    let id: String
    var name: String
    var icon: String
    var isEnabled: Bool
    var triggers: [RoutineTrigger]
    var actions: [RoutineAction]
    var vehicleId: String?
    var lastTriggered: Date?
    var triggerCount: Int
    var isAISuggested: Bool
    var confidence: Double?
    var createdAt: Date

    var statusText: String {
        if !isEnabled { return "Disabled" }
        if let last = lastTriggered {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .short
            return "Last: \(formatter.localizedString(for: last, relativeTo: Date()))"
        }
        return "Ready"
    }
}

nonisolated enum RoutineTrigger: Codable, Hashable, Sendable {
    case timeOfDay(hour: Int, minute: Int)
    case dayOfWeek(days: [Int])
    case location(latitude: Double, longitude: Double, radius: Double, name: String)
    case locationLeave(latitude: Double, longitude: Double, radius: Double, name: String)
    case batteryBelow(level: Int)
    case batteryAbove(level: Int)
    case chargingStateChange(to: ChargingState)
    case temperatureBelow(celsius: Double)
    case temperatureAbove(celsius: Double)
    case vehicleParked
    case vehicleMoving
    case sunriseOffset(minutes: Int)
    case sunsetOffset(minutes: Int)

    var displayName: String {
        switch self {
        case .timeOfDay(let h, let m): return String(format: "At %d:%02d", h, m)
        case .dayOfWeek(let days):
            let names = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
            return days.map { names[$0 % 7] }.joined(separator: ", ")
        case .location(_, _, _, let name): return "Arrive at \(name)"
        case .locationLeave(_, _, _, let name): return "Leave \(name)"
        case .batteryBelow(let v): return "Battery below \(v)%"
        case .batteryAbove(let v): return "Battery above \(v)%"
        case .chargingStateChange(let s): return "Charging: \(s.rawValue)"
        case .temperatureBelow(let t): return "Temp below \(Int(t))°"
        case .temperatureAbove(let t): return "Temp above \(Int(t))°"
        case .vehicleParked: return "Vehicle parked"
        case .vehicleMoving: return "Vehicle moving"
        case .sunriseOffset(let m): return m == 0 ? "At sunrise" : "\(m)min from sunrise"
        case .sunsetOffset(let m): return m == 0 ? "At sunset" : "\(m)min from sunset"
        }
    }

    var icon: String {
        switch self {
        case .timeOfDay: return "clock"
        case .dayOfWeek: return "calendar"
        case .location: return "location.fill"
        case .locationLeave: return "location.slash"
        case .batteryBelow, .batteryAbove: return "battery.50percent"
        case .chargingStateChange: return "bolt.fill"
        case .temperatureBelow, .temperatureAbove: return "thermometer"
        case .vehicleParked: return "parkingsign"
        case .vehicleMoving: return "car.fill"
        case .sunriseOffset: return "sunrise.fill"
        case .sunsetOffset: return "sunset.fill"
        }
    }
}

nonisolated enum RoutineAction: Codable, Hashable, Sendable {
    case preconditionCabin(targetTemp: Double)
    case startCharging
    case stopCharging
    case setChargeLimit(percent: Int)
    case lockVehicle
    case unlockVehicle
    case enableSentryMode
    case disableSentryMode
    case openFrunk
    case openTrunk
    case flashLights
    case honkHorn
    case navigateTo(latitude: Double, longitude: Double, name: String)
    case sendNotification(message: String)
    case shareETA(contactName: String)
    case playMedia(source: String)

    var displayName: String {
        switch self {
        case .preconditionCabin(let t): return "Set cabin to \(Int(t))°"
        case .startCharging: return "Start charging"
        case .stopCharging: return "Stop charging"
        case .setChargeLimit(let p): return "Set charge limit to \(p)%"
        case .lockVehicle: return "Lock vehicle"
        case .unlockVehicle: return "Unlock vehicle"
        case .enableSentryMode: return "Enable Sentry Mode"
        case .disableSentryMode: return "Disable Sentry Mode"
        case .openFrunk: return "Open frunk"
        case .openTrunk: return "Open trunk"
        case .flashLights: return "Flash lights"
        case .honkHorn: return "Honk horn"
        case .navigateTo(_, _, let n): return "Navigate to \(n)"
        case .sendNotification(let m): return "Notify: \(m)"
        case .shareETA(let c): return "Share ETA with \(c)"
        case .playMedia(let s): return "Play \(s)"
        }
    }

    var icon: String {
        switch self {
        case .preconditionCabin: return "thermometer.snowflake"
        case .startCharging, .stopCharging: return "bolt.fill"
        case .setChargeLimit: return "battery.75percent"
        case .lockVehicle: return "lock.fill"
        case .unlockVehicle: return "lock.open.fill"
        case .enableSentryMode, .disableSentryMode: return "eye.fill"
        case .openFrunk, .openTrunk: return "car.top.door.front.left.open"
        case .flashLights: return "lightbulb.fill"
        case .honkHorn: return "speaker.wave.3.fill"
        case .navigateTo: return "location.fill"
        case .sendNotification: return "bell.fill"
        case .shareETA: return "paperplane.fill"
        case .playMedia: return "play.fill"
        }
    }
}
