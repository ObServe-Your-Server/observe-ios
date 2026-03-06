import Foundation

enum MachineStatus: String, Codable, CaseIterable {
    case healthy  = "HEALTHY"
    case warning  = "WARNING"
    case critical = "CRITICAL"
    case offline  = "OFFLINE"
    case unknown  = "UNKNOWN"

    var isHealthy: Bool { self == .healthy }

    private var severity: Int {
        switch self {
        case .unknown:  return 0
        case .healthy:  return 1
        case .warning:  return 2
        case .critical: return 3
        case .offline:  return 4
        }
    }

    // MARK: - Algorithm

    static func compute(from metric: MachineMetricResponse?, isConnected: Bool) -> MachineStatus {
        guard isConnected else { return .offline }
        guard let m = metric else { return .unknown }

        var statuses: [MachineStatus] = []

        if let cpu = m.cpuUsage {
            statuses.append(level(cpu, warning: 80, critical: 95))
        }
        if let temp = m.cpuTemperature {
            statuses.append(level(temp, warning: 75, critical: 85))
        }
        if let used = m.memUsed, let total = m.memTotal, total > 0 {
            statuses.append(level(Double(used) / Double(total) * 100, warning: 85, critical: 95))
        }
        for disk in m.disks ?? [] {
            if let used = disk.used, let total = disk.total, total > 0 {
                statuses.append(level(Double(used) / Double(total) * 100, warning: 85, critical: 95))
            }
        }

        guard !statuses.isEmpty else { return .unknown }
        return statuses.max(by: { $0.severity < $1.severity }) ?? .unknown
    }

    private static func level(_ v: Double, warning: Double, critical: Double) -> MachineStatus {
        if v >= critical { return .critical }
        if v >= warning  { return .warning }
        return .healthy
    }
}
