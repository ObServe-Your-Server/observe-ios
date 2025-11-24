import Foundation

struct CpuUsageResponse: Decodable {
    let unixTime: Int
    let usageInPercent: String
}
