import Foundation

@MainActor
class ServerLogsManager: ObservableObject {
    // MARK: - Singleton

    static let shared = ServerLogsManager()

    // MARK: - Constants

    private let maxPersistedEntries = 50
    private let defaults = UserDefaults.standard
    private let storageKeyPrefix = "server_logs_v2_"

    // MARK: - Storage

    @Published private var logsByServer: [UUID: [ServerLogEntry]] = [:]

    private init() {}

    // MARK: - Frontend-generated entries

    func addFrontendEntry(serverId: UUID, severity: LogSeverity, title: String, detail: String? = nil) {
        var entries = logsByServer[serverId] ?? loadPersistedLogs(for: serverId)
        let entry = ServerLogEntry(severity: severity, title: title, detail: detail, serverId: serverId)
        entries.append(entry)
        let trimmed = Array(entries.suffix(maxPersistedEntries))
        logsByServer[serverId] = trimmed
        persistLogs(trimmed, for: serverId)
    }

    // MARK: - Read

    func getLogs(for serverId: UUID) -> [ServerLogEntry] {
        if logsByServer[serverId] == nil {
            logsByServer[serverId] = loadPersistedLogs(for: serverId)
        }
        return (logsByServer[serverId] ?? []).reversed()
    }

    // MARK: - Fetch from backend

    func fetchAndPersist(machineUUID: UUID, serverId: UUID) async {
        let fetched: [NotificationEntityResponse]
        do {
            fetched = try await WatchTowerAPI.shared.fetchNotifications(
                machineUUID: machineUUID,
                last: maxPersistedEntries
            )
        } catch {
            print("ServerLogsManager: fetch failed for \(machineUUID): \(error)")
            return
        }

        print("ServerLogsManager: fetched \(fetched.count) notifications for \(machineUUID)")

        let entries: [ServerLogEntry] = fetched.compactMap { n -> ServerLogEntry? in
            guard let iso = n.createdAt else {
                print("ServerLogsManager: skipping entry \(n.uuid) — no createdAt")
                return nil
            }
            guard let date = parseISO(iso) else {
                print("ServerLogsManager: skipping entry \(n.uuid) — unparseable date '\(iso)'")
                return nil
            }
            let sev = mapSeverity(n.severity)
            let interpreted = NotificationInterpreter.interpret(
                component: n.component,
                severity: n.severity,
                message: n.message
            )
            return ServerLogEntry(
                id: UUID(uuidString: n.uuid) ?? UUID(),
                timestamp: date,
                severity: sev,
                title: interpreted.title,
                detail: interpreted.description,
                serverId: serverId
            )
        }

        // Merge with existing persisted entries so history isn't lost between fetches
        let existing = loadPersistedLogs(for: serverId)
        var merged = existing
        let existingIds = Set(existing.map(\.id))
        for entry in entries where !existingIds.contains(entry.id) {
            merged.append(entry)
        }
        let sorted = Array(merged.sorted { $0.timestamp < $1.timestamp }.suffix(maxPersistedEntries))
        print("ServerLogsManager: persisting \(sorted.count) entries for serverId \(serverId)")
        logsByServer[serverId] = sorted
        persistLogs(sorted, for: serverId)
    }

    // MARK: - Persistence

    private func storageKey(for serverId: UUID) -> String {
        storageKeyPrefix + serverId.uuidString
    }

    private func persistLogs(_ entries: [ServerLogEntry], for serverId: UUID) {
        let toSave = Array(entries.suffix(maxPersistedEntries))
        if let data = try? JSONEncoder().encode(toSave) {
            defaults.set(data, forKey: storageKey(for: serverId))
        }
    }

    private func loadPersistedLogs(for serverId: UUID) -> [ServerLogEntry] {
        guard let data = defaults.data(forKey: storageKey(for: serverId)),
              let entries = try? JSONDecoder().decode([ServerLogEntry].self, from: data)
        else {
            return []
        }
        return entries
    }

    // MARK: - Helpers

    private func mapSeverity(_ raw: String?) -> LogSeverity {
        switch raw {
        case "Critical": .critical
        case "Warning": .warning
        default: .info
        }
    }

    private func parseISO(_ iso: String) -> Date? {
        let localFmt = DateFormatter()
        localFmt.locale = Locale(identifier: "en_US_POSIX")
        // Truncate fractional seconds to 3 digits so DateFormatter handles micro/nanoseconds too
        let normalized = iso.replacingOccurrences(
            of: #"(\.\d{3})\d+"#,
            with: "$1",
            options: .regularExpression
        )
        localFmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        if let d = localFmt.date(from: normalized) { return d }
        localFmt.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return localFmt.date(from: normalized)
    }
}
