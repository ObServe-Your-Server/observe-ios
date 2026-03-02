//
//  ServerQuery.swift
//  observeMetricsWidget
//
//  Created by Daniel Schatz on 21.10.25.
//

import Foundation
import AppIntents

/// Entity representing a server for widget configuration
struct ServerEntity: AppEntity, Identifiable {
    let id: String
    let serverId: UUID
    let machineUUID: UUID
    let displayString: String
    let isConnected: Bool
    let isHealthy: Bool

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Server"

    static var defaultQuery = ServerQuery()

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(displayString)",
            subtitle: isConnected ? "Connected" : "Disconnected"
        )
    }
}

/// Query to fetch available servers from shared storage
struct ServerQuery: EntityStringQuery {
    private func loadServers() -> [ServerEntity] {
        let servers = SharedStorageManager.shared.loadServers()
        return servers.map { ServerEntity(fromSharedServer: $0) }
    }

    // MARK: - EntityQuery Protocol

    func entities(for identifiers: [String]) async throws -> [ServerEntity] {
        let allServers = loadServers()
        return allServers.filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [ServerEntity] {
        return loadServers()
    }

    func defaultResult() async -> ServerEntity? {
        return loadServers().first
    }

    // MARK: - EntityStringQuery Protocol

    func entities(matching string: String) async throws -> [ServerEntity] {
        let allServers = loadServers()

        if string.isEmpty {
            return allServers
        }

        let lowercasedQuery = string.lowercased()
        return allServers.filter {
            $0.displayString.lowercased().contains(lowercasedQuery)
        }
    }
}

// MARK: - ServerEntity Extensions

extension ServerEntity {
    init(fromSharedServer sharedServer: SharedServer) {
        self.id = sharedServer.id.uuidString
        self.serverId = sharedServer.id
        self.machineUUID = sharedServer.machineUUID
        self.displayString = sharedServer.name
        self.isConnected = sharedServer.isConnected
        self.isHealthy = sharedServer.isHealthy
    }

    func toSharedServer() -> SharedServer {
        return SharedServer(
            id: self.serverId,
            machineUUID: self.machineUUID,
            name: self.displayString,
            type: "",
            isConnected: self.isConnected,
            isHealthy: self.isHealthy,
            lastConnected: nil,
            uptime: nil
        )
    }
}
