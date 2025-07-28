import Foundation

struct RamResponse: Decodable {
    struct Result: Decodable {
        let metric: [String: String]
        let values: [RamValue] // Changed from [[RamValue]] to [RamValue]
    }
    struct RamValue: Decodable {
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
