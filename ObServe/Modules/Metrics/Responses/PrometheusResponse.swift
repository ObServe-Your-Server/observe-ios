import Foundation

// Consolidated response model for Prometheus-style metrics
struct PrometheusResponse: Decodable {
    struct Result: Decodable {
        let metric: [String: String]
        let values: [PrometheusValue]
    }
    
    struct PrometheusValue: Decodable {
        let timestamp: Double
        let value: Double
        
        init(from decoder: Decoder) throws {
            var container = try decoder.unkeyedContainer()
            self.timestamp = try container.decode(Double.self)
            let valueString = try container.decode(String.self)
            self.value = Double(valueString) ?? 0
        }
    }
    
    struct Data: Decodable {
        let resultType: String
        let result: [Result]
    }
    
    let status: String
    let data: Data
}

// Type aliases for existing response types to maintain compatibility
typealias RamResponse = PrometheusResponse
typealias TotalDiskResponse = PrometheusResponse
typealias TotalRamResponse = PrometheusResponse

// Simple responses matching OpenAPI spec
typealias UptimeResponse = Int
