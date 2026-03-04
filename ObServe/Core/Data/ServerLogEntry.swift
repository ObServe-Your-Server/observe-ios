import Foundation

// MARK: - Log Severity

enum LogSeverity: String, Codable, CaseIterable {
    case info     = "INFO"
    case warning  = "WARNING"
    case critical = "CRITICAL"

    var colorName: String {
        switch self {
        case .info:     return "ObServeBlue"
        case .warning:  return "ObServeOrange"
        case .critical: return "ObServeRed"
        }
    }
}

// MARK: - Log Entry

struct ServerLogEntry: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let severity: LogSeverity
    let title: String
    let detail: String?
    let serverId: UUID

    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        severity: LogSeverity,
        title: String,
        detail: String? = nil,
        serverId: UUID
    ) {
        self.id = id
        self.timestamp = timestamp
        self.severity = severity
        self.title = title
        self.detail = detail
        self.serverId = serverId
    }
}
