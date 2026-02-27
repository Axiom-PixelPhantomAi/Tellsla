import Foundation

actor CrashLogService {
    static let shared = CrashLogService()
    private let maxLogs = 500
    private let logKey = "crash_logs_v1"

    func log(_ level: LogLevel, message: String, context: String? = nil) {
        var logs = loadLogs()
        let entry = CrashLogEntry(
            id: UUID().uuidString,
            timestamp: Date(),
            level: level,
            message: message,
            context: context
        )
        logs.insert(entry, at: 0)
        if logs.count > maxLogs {
            logs = Array(logs.prefix(maxLogs))
        }
        saveLogs(logs)
    }

    func getLogs() -> [CrashLogEntry] {
        loadLogs()
    }

    func clearLogs() {
        saveLogs([])
    }

    private func loadLogs() -> [CrashLogEntry] {
        guard let data = UserDefaults.standard.data(forKey: logKey),
              let logs = try? JSONDecoder().decode([CrashLogEntry].self, from: data) else {
            return []
        }
        return logs
    }

    private func saveLogs(_ logs: [CrashLogEntry]) {
        if let data = try? JSONEncoder().encode(logs) {
            UserDefaults.standard.set(data, forKey: logKey)
        }
    }
}
