//
//  OverViewModel.swift
//  ObServe
//

import SwiftUI
import SwiftData
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
            let existingUUIDs = Set(existingServers.compactMap { $0.machineUUID })

            for remote in remoteMachines {
                guard let uuid = UUID(uuidString: remote.uuid) else { continue }

                if !existingUUIDs.contains(uuid) {
                    let newServer = ServerModuleItem(
                        machineUUID: uuid,
                        name: remote.name ?? "Unknown",
                        type: remote.type ?? "SERVER",
                        apiKey: remote.apiKey ?? ""
                    )
                    newServer.isConnected = true
                    newServer.isHealthy = true
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

    // MARK: - Widget Sync

    func syncServersToWidget(_ servers: [ServerModuleItem]) {
        let sharedServers = servers.map { $0.toSharedServer() }
        SharedStorageManager.shared.saveServers(sharedServers)
        WidgetCenter.shared.reloadAllTimelines()
        print("OverViewModel: Synced \(sharedServers.count) servers to widget")
    }
}
