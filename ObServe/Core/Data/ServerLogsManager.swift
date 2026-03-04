import Foundation

@MainActor
class ServerLogsManager: ObservableObject {

    // MARK: - Singleton

    static let shared = ServerLogsManager()

    // MARK: - Constants

    private let maxEntriesPerServer = 500
    private let persistedEntriesPerServer = 50
    private let defaults = UserDefaults.standard
    private let storageKeyPrefix = "server_logs_"

    // MARK: - Storage

    @Published private var logsByServer: [UUID: [ServerLogEntry]] = [:]

    private init() {
        // No eager load — logs are loaded on first access per server
    }

    // MARK: - Write

    func addLog(serverId: UUID, severity: LogSeverity, title: String, detail: String? = nil) {
        let entry = ServerLogEntry(severity: severity, title: title, detail: detail, serverId: serverId)
        var entries = logsByServer[serverId] ?? loadPersistedLogs(for: serverId)
        entries.append(entry)
        if entries.count > maxEntriesPerServer {
            entries = Array(entries.suffix(maxEntriesPerServer))
        }
        logsByServer[serverId] = entries
        persistLogs(entries, for: serverId)
    }

    // MARK: - Read

    func getLogs(for serverId: UUID) -> [ServerLogEntry] {
        if logsByServer[serverId] == nil {
            logsByServer[serverId] = loadPersistedLogs(for: serverId)
        }
        return (logsByServer[serverId] ?? []).reversed()
    }

    // MARK: - Clear

    func clearLogs(for serverId: UUID) {
        logsByServer[serverId] = nil
        defaults.removeObject(forKey: storageKey(for: serverId))
    }

    // MARK: - Persistence

    private func storageKey(for serverId: UUID) -> String {
        storageKeyPrefix + serverId.uuidString
    }

    private func persistLogs(_ entries: [ServerLogEntry], for serverId: UUID) {
        let toSave = Array(entries.suffix(persistedEntriesPerServer))
        if let data = try? JSONEncoder().encode(toSave) {
            defaults.set(data, forKey: storageKey(for: serverId))
        }
    }

    private func loadPersistedLogs(for serverId: UUID) -> [ServerLogEntry] {
        guard let data = defaults.data(forKey: storageKey(for: serverId)),
              let entries = try? JSONDecoder().decode([ServerLogEntry].self, from: data) else {
            return []
        }
        return entries
    }
}
