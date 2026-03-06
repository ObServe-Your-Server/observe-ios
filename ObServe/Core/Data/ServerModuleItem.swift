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
    var lastConnected: Date?
    var isConnected: Bool = false
    var isHealthy: Bool = false
    var statusRawValue: String = MachineStatus.unknown.rawValue

    var machineStatus: MachineStatus {
        get { MachineStatus(rawValue: statusRawValue) ?? .unknown }
        set { statusRawValue = newValue.rawValue; isHealthy = newValue.isHealthy }
    }

    init(machineUUID: UUID, name: String, type: String, apiKey: String = "", machineDescription: String = "", location: String = "") {
        self.machineUUID = machineUUID
        self.name = name
        self.type = type
        self.apiKey = apiKey
        self.machineDescription = machineDescription
        self.location = location
    }

    /// Convert to SharedServer for widget communication
    func toSharedServer() -> SharedServer {
        return SharedServer(
            id: self.id,
            machineUUID: self.machineUUID,
            name: self.name,
            type: self.type,
            isConnected: self.isConnected,
            isHealthy: self.isHealthy,
            statusRawValue: self.statusRawValue,
            lastConnected: self.lastConnected,
            uptime: nil
        )
    }
}
