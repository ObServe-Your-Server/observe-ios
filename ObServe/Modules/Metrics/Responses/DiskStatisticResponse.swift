import Foundation

struct DiskStatisticResponse: Decodable {
    let unixTime: Int
    let totalUsedSpaceAllDisksInGb: String
    let totalAvailableSpaceAllDisksInGb: String
}
