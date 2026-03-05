import Foundation

// MARK: - Metric Responses

struct MachineMetricResponse: Decodable {
    let uuid: String
    let capturedAt: String
    let cpuUsage: Double?
    let cpuTemperature: Double?
    let memUsed: Int64?
    let memTotal: Int64?
    let disks: [DiskPayloadResponse]?
    let netBytesIn: Int64?
    let netBytesOut: Int64?
    let localIp: String?
    let uptime: Int64?
    let speedtest: SpeedtestPayloadResponse?
    let osName: String?
    let kernelVersion: String?
    let cpuName: String?
    let cpuCount: Int64?
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
