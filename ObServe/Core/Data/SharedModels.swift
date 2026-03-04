import Foundation

/// Shared server model for App Group communication between main app and widget
struct SharedServer: Codable, Identifiable {
    let id: UUID
    let machineUUID: UUID
    let name: String
    let type: String
    let isConnected: Bool
    let isHealthy: Bool
    let statusRawValue: String
    let lastConnected: Date?
    let uptime: TimeInterval?

    var machineStatus: MachineStatus {
        MachineStatus(rawValue: statusRawValue) ?? .unknown
    }

    init(id: UUID, machineUUID: UUID, name: String, type: String = "", isConnected: Bool, isHealthy: Bool, statusRawValue: String = MachineStatus.unknown.rawValue, lastConnected: Date? = nil, uptime: TimeInterval? = nil) {
        self.id = id
        self.machineUUID = machineUUID
        self.name = name
        self.type = type
        self.isConnected = isConnected
        self.isHealthy = isHealthy
        self.statusRawValue = statusRawValue
        self.lastConnected = lastConnected
        self.uptime = uptime
    }
}

/// Cached metric data for widget display
struct SharedMetricData: Codable {
    let serverId: UUID
    let metricType: String
    let value: Double
    let timestamp: Date
    let history: [Double]

    init(serverId: UUID, metricType: String, value: Double, timestamp: Date, history: [Double] = []) {
        self.serverId = serverId
        self.metricType = metricType
        self.value = value
        self.timestamp = timestamp
        self.history = history
    }

    var isFresh: Bool {
        return Date().timeIntervalSince(timestamp) < 120
    }

    var ageInSeconds: TimeInterval {
        return Date().timeIntervalSince(timestamp)
    }
}

/// Available metric types
enum MetricType: String, Codable, CaseIterable {
    case cpu = "CPU"
    case ram = "RAM"
    case networkIn = "Network In"
    case networkOut = "Network Out"
    case storage = "Storage"
    case cpuTemperature = "CPU Temp"

    var displayName: String {
        return self.rawValue
    }
}
