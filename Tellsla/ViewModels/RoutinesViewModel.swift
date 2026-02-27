import SwiftUI

@Observable
@MainActor
class RoutinesViewModel {
    var routines: [Routine] = []
    var suggestedRoutines: [Routine] = []
    var isLoading: Bool = false
    var activeRoutine: Routine?
    var showRoutineEditor: Bool = false
    var editingRoutine: Routine?
    var routineTemplates: [RoutineTemplate] = []

    init() {
        loadRoutines()
        generateSuggestions()
        loadTemplates()
    }

    func toggleRoutine(_ routine: Routine) {
        guard let index = routines.firstIndex(where: { $0.id == routine.id }) else { return }
        routines[index].isEnabled.toggle()
        saveRoutines()
    }

    func deleteRoutine(_ routine: Routine) {
        routines.removeAll { $0.id == routine.id }
        saveRoutines()
    }

    func addRoutine(_ routine: Routine) {
        routines.append(routine)
        saveRoutines()
    }

    func updateRoutine(_ routine: Routine) {
        guard let index = routines.firstIndex(where: { $0.id == routine.id }) else { return }
        routines[index] = routine
        saveRoutines()
    }

    func acceptSuggestion(_ routine: Routine) {
        var accepted = routine
        accepted.isAISuggested = false
        routines.append(accepted)
        suggestedRoutines.removeAll { $0.id == routine.id }
        saveRoutines()
    }

    func dismissSuggestion(_ routine: Routine) {
        suggestedRoutines.removeAll { $0.id == routine.id }
    }

    func triggerRoutine(_ routine: Routine) async {
        activeRoutine = routine
        guard let index = routines.firstIndex(where: { $0.id == routine.id }) else { return }
        routines[index].lastTriggered = Date()
        routines[index].triggerCount += 1
        saveRoutines()

        try? await Task.sleep(for: .seconds(2))
        activeRoutine = nil
    }

    func installTemplate(_ template: RoutineTemplate) {
        let routine = Routine(
            id: UUID().uuidString,
            name: template.name,
            icon: template.icon,
            isEnabled: true,
            triggers: template.triggers,
            actions: template.actions,
            vehicleId: nil,
            lastTriggered: nil,
            triggerCount: 0,
            isAISuggested: false,
            confidence: nil,
            createdAt: Date()
        )
        addRoutine(routine)
    }

    private func loadRoutines() {
        if let data = UserDefaults.standard.data(forKey: "saved_routines"),
           let decoded = try? JSONDecoder().decode([Routine].self, from: data) {
            routines = decoded
        }
    }

    private func saveRoutines() {
        if let data = try? JSONEncoder().encode(routines) {
            UserDefaults.standard.set(data, forKey: "saved_routines")
        }
    }

    private func generateSuggestions() {
        suggestedRoutines = [
            Routine(
                id: "sug_morning",
                name: "Morning Commute",
                icon: "sunrise.fill",
                isEnabled: true,
                triggers: [.timeOfDay(hour: 7, minute: 30), .dayOfWeek(days: [1, 2, 3, 4, 5])],
                actions: [.preconditionCabin(targetTemp: 21), .navigateTo(latitude: 37.3861, longitude: -122.0839, name: "Work")],
                vehicleId: nil, lastTriggered: nil, triggerCount: 0,
                isAISuggested: true, confidence: 0.87, createdAt: Date()
            ),
            Routine(
                id: "sug_friday",
                name: "Friday Lake Trip",
                icon: "water.waves",
                isEnabled: true,
                triggers: [.timeOfDay(hour: 17, minute: 0), .dayOfWeek(days: [5])],
                actions: [.preconditionCabin(targetTemp: 22), .navigateTo(latitude: 39.0968, longitude: -120.0324, name: "Lake House"), .shareETA(contactName: "Partner")],
                vehicleId: nil, lastTriggered: nil, triggerCount: 0,
                isAISuggested: true, confidence: 0.73, createdAt: Date()
            ),
            Routine(
                id: "sug_lowbat",
                name: "Low Battery Alert",
                icon: "battery.25percent",
                isEnabled: true,
                triggers: [.batteryBelow(level: 20)],
                actions: [.sendNotification(message: "Battery below 20%"), .navigateTo(latitude: 37.4, longitude: -122.1, name: "Nearest Supercharger")],
                vehicleId: nil, lastTriggered: nil, triggerCount: 0,
                isAISuggested: true, confidence: 0.92, createdAt: Date()
            ),
        ]
    }

    private func loadTemplates() {
        routineTemplates = [
            RoutineTemplate(
                id: "t_winter", name: "Winter Morning", icon: "snowflake",
                description: "Pre-heat cabin 30 min before calendar departure",
                category: .weather,
                triggers: [.timeOfDay(hour: 6, minute: 30), .temperatureBelow(celsius: 5)],
                actions: [.preconditionCabin(targetTemp: 22)],
                rating: 4.8, installCount: 2340
            ),
            RoutineTemplate(
                id: "t_roadtrip", name: "Road Trip Ready", icon: "car.fill",
                description: "Charge to 90%, check tire pressure, set nav",
                category: .trips,
                triggers: [.batteryAbove(level: 89)],
                actions: [.setChargeLimit(percent: 90), .sendNotification(message: "Road trip ready!")],
                rating: 4.6, installCount: 1890
            ),
            RoutineTemplate(
                id: "t_home", name: "Arrive Home", icon: "house.fill",
                description: "Set charge limit to 80% when parked at home",
                category: .charging,
                triggers: [.location(latitude: 37.78, longitude: -122.41, radius: 200, name: "Home")],
                actions: [.setChargeLimit(percent: 80), .disableSentryMode],
                rating: 4.9, installCount: 3100
            ),
            RoutineTemplate(
                id: "t_work", name: "Leave Work", icon: "briefcase.fill",
                description: "Pre-condition and navigate home when leaving work",
                category: .commute,
                triggers: [.locationLeave(latitude: 37.39, longitude: -122.08, radius: 300, name: "Work")],
                actions: [.preconditionCabin(targetTemp: 21), .navigateTo(latitude: 37.78, longitude: -122.41, name: "Home")],
                rating: 4.7, installCount: 2560
            ),
            RoutineTemplate(
                id: "t_security", name: "Night Security", icon: "moon.fill",
                description: "Enable Sentry and lock at 10pm",
                category: .security,
                triggers: [.timeOfDay(hour: 22, minute: 0)],
                actions: [.enableSentryMode, .lockVehicle],
                rating: 4.5, installCount: 1450
            ),
        ]
    }
}
