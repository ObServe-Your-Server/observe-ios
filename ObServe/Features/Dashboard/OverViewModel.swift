import SwiftData
import SwiftUI
import WidgetKit

@MainActor
class OverViewModel: ObservableObject {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Backend Sync

    func syncMachinesFromBackend(existingServers: [ServerModuleItem]) async {
        do {
            let remoteMachines = try await WatchTowerAPI.shared.fetchMachines()
            let existingUUIDs = Set(existingServers.compactMap(\.machineUUID))

            for remote in remoteMachines {
                guard let uuid = UUID(uuidString: remote.uuid) else { continue }

                if let existing = existingServers.first(where: { $0.machineUUID == uuid }) {
                    if existing.createdAt == nil, let createdAtStr = remote.createdAt {
                        existing.createdAt = Self.parseISO8601(createdAtStr)
                    }
                } else {
                    let newServer = ServerModuleItem(
                        machineUUID: uuid,
                        name: remote.name ?? "Unknown",
                        type: remote.type ?? "SERVER",
                        apiKey: remote.apiKey ?? ""
                    )
                    newServer.isConnected = true
                    newServer.isHealthy = true
                    if let createdAtStr = remote.createdAt {
                        newServer.createdAt = Self.parseISO8601(createdAtStr)
                    }
                    modelContext.insert(newServer)
                }
            }

            try? modelContext.save()
            syncServersToWidget(existingServers)
        } catch {
            print("OverViewModel: Failed to sync machines from backend: \(error.localizedDescription)")
        }
    }

    // MARK: - Delete

    func deleteServer(_ server: ServerModuleItem, allServers: [ServerModuleItem]) async {
        do {
            try await WatchTowerAPI.shared.deleteMachine(uuid: server.machineUUID)
        } catch {
            print("OverViewModel: Failed to delete machine from backend: \(error.localizedDescription)")
            // Still delete locally even if backend fails
        }

        withAnimation {
            modelContext.delete(server)
            try? modelContext.save()
            syncServersToWidget(allServers)
        }
    }

    // MARK: - Helpers

    private static func parseISO8601(_ string: String) -> Date? {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        for format in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss.SSS", "yyyy-MM-dd'T'HH:mm:ss"] {
            f.dateFormat = format
            if let date = f.date(from: string) { return date }
        }
        return ISO8601DateFormatter().date(from: string)
    }

    // MARK: - Widget Sync

    func syncServersToWidget(_ servers: [ServerModuleItem]) {
        let sharedServers = servers.map { $0.toSharedServer() }
        SharedStorageManager.shared.saveServers(sharedServers)
        WidgetCenter.shared.reloadAllTimelines()
        print("OverViewModel: Synced \(sharedServers.count) servers to widget")
    }
}
