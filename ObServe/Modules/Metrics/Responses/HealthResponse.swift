import Foundation

struct HealthResponse: Decodable {
    let health: String
    let version: String
    let prometheusConnection: String
    let nodeExporterConnection: String
}
