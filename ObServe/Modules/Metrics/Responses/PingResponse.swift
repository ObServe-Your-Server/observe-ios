import Foundation

struct PingResponse: Decodable {
    let address: String?
    let timestamp: String?
    let requestedBy: String?
    let success: Bool?
    let exitCode: Int?
    let errorMessage: String?
    let totalExecutionTimeMs: Int?
    let packetCount: Int?
    let timeoutSeconds: Int?
    let packetsSent: Int?
    let packetsReceived: Int?
    let packetsLost: Int?
    let packetLossPercentage: Double?
    let minLatencyMs: Double?
    let maxLatencyMs: Double?
    let avgLatencyMs: Double?
    let stdDeviationMs: Double?
    let latencies: [Double]?
    let ttl: Int?
    let sequences: [Int]?
    let rawOutput: String?
    let errorOutput: String?
    let operatingSystem: String?
    let javaVersion: String?
    let resolvedIpAddress: String?
    let dnsLookupTimeMs: Double?
}
