import Foundation

// MARK: - Metric Responses

struct MachineMetricResponse: Decodable {
    let uuid: String
    let capturedAt: String
    let cpuUsage: Double?
    let cpuTemperature: Double?
    let cpuName: String?
    let cpuCount: Int64?
    let memUsed: Int64?
    let memTotal: Int64?
    let disks: [DiskPayloadResponse]?
    let netBytesIn: Int64?
    let netBytesOut: Int64?
    let netBytesInPerSecond: Int64?
    let netBytesOutPerSecond: Int64?
    let localIp: String?
    let speedtest: SpeedtestPayloadResponse?
    let uptime: Int64?
    let osName: String?
    let kernelVersion: String?
    let hostname: String?
}

struct DockerMetricsResponse: Decodable {
    let uuid: String?
    let capturedAt: String?
    let containers: [ContainerStatResponse]?
}

struct ContainerStatResponse: Decodable, Identifiable {
    let uuid: String?
    let containerId: String?
    let hostName: String?
    let createdAt: Int64?
    let status: String?
    let running: Bool?
    let runningForSeconds: Int64?
    let imageName: String?
    let networks: [String]?
    let cpuUsagePercent: Double?
    let memoryUsageBytes: Int64?

    var id: String {
        uuid ?? containerId ?? ""
    }
}

struct DiskPayloadResponse: Decodable {
    let name: String?
    let total: Int64?
    let used: Int64?
}

struct SpeedtestPayloadResponse: Decodable {
    let pingMs: Double?
    let uploadMbps: Double?
    let downloadMbps: Double?
}

// MARK: - Machine Responses

struct MachineEntityResponse: Decodable {
    let uuid: String
    let ownerId: String?
    let type: String?
    let name: String?
    let description: String?
    let location: String?
    let apiKey: String?
    let createdAt: String?
    let updatedAt: String?
}

// MARK: - Machine Requests

struct CreateMachineRequest: Encodable {
    let type: String
    let name: String
    let description: String?
    let location: String?
}

struct UpdateMachineRequest: Encodable {
    let type: String?
    let name: String?
    let description: String?
    let location: String?
}

// MARK: - Notification Responses

struct NotificationEntityResponse: Decodable, Identifiable {
    let uuid: String
    let severity: String?
    let component: String?
    let message: String?
    let createdAt: String?

    var id: String {
        uuid
    }
}

// MARK: - User Responses

struct UserInfoResponse: Decodable {
    let sub: String?
    let preferredUsername: String?
    let email: String?
    let name: String?
    let givenName: String?
    let nickname: String?
    let roles: Set<String>?
}
