import SwiftData
import SwiftUI

@Model
class ServerModuleItem {
    var id: UUID = UUID()
    var machineUUID: UUID = UUID()
    var name: String = ""
    var type: String = ""
    var machineDescription: String = ""
    var location: String = ""
    var apiKey: String = ""
    var createdAt: Date?
    var lastConnected: Date?
    var isConnected: Bool = false
    var isHealthy: Bool = false
    var statusRawValue: String = MachineStatus.unknown.rawValue
    var sortOrder: Int = 0

    var machineStatus: MachineStatus {
        get { MachineStatus(rawValue: statusRawValue) ?? .unknown }
        set { statusRawValue = newValue.rawValue
            isHealthy = newValue.isHealthy
        }
    }

    init(
        machineUUID: UUID,
        name: String,
        type: String,
        apiKey: String = "",
        machineDescription: String = "",
        location: String = "",
        sortOrder: Int = 0
    ) {
        self.machineUUID = machineUUID
        self.name = name
        self.type = type
        self.apiKey = apiKey
        self.machineDescription = machineDescription
        self.location = location
        self.sortOrder = sortOrder
    }

    /// Convert to SharedServer for widget communication
    func toSharedServer() -> SharedServer {
        SharedServer(
            id: id,
            machineUUID: machineUUID,
            name: name,
            type: type,
            isConnected: isConnected,
            isHealthy: isHealthy,
            statusRawValue: statusRawValue,
            lastConnected: lastConnected,
            uptime: nil
        )
    }
}
