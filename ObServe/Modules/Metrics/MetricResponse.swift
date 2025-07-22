import Foundation

struct MetricResponse: Decodable {
    struct Entry: Identifiable {
        let id = UUID()
        let timestamp: Double
        let value: Double
    }

    let metrics: [Entry]

    private enum CodingKeys: String, CodingKey {
        case metric
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let rawDict = try container.decode([String: Double].self, forKey: .metric)

        self.metrics = rawDict.compactMap { key, value in
            if let ts = Double(key) {
                return Entry(timestamp: ts, value: value)
            } else {
                return nil
            }
        }
        .sorted { $0.timestamp < $1.timestamp }
    }
}
