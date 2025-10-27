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
    let id: String // AppEntity requires String ID
    let serverId: UUID
    let displayString: String
    let ip: String
    let port: String
    let apiKey: String
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
    // Simplified - no caching during configuration to avoid race conditions
    private func loadServers() -> [ServerEntity] {
        print("ServerQuery: Loading servers from SharedStorageManager...")
        let servers = SharedStorageManager.shared.loadServers()
        print("ServerQuery: Loaded \(servers.count) server(s) from storage")

        if servers.isEmpty {
            print("ServerQuery: No servers found!")
        }

        return servers.map { ServerEntity(fromSharedServer: $0) }
    }

    // MARK: - EntityQuery Protocol

    func entities(for identifiers: [String]) async throws -> [ServerEntity] {
        print("ServerQuery: entities(for:) called with \(identifiers.count) identifier(s)")
        let allServers = loadServers()
        let result = allServers.filter { identifiers.contains($0.id) }
        print("ServerQuery: Found \(result.count) matching server(s)")
        return result
    }

    func suggestedEntities() async throws -> [ServerEntity] {
        print("ServerQuery: suggestedEntities() called")
        let result = loadServers()
        print("ServerQuery: Returning \(result.count) suggested server(s)")
        return result
    }

    func defaultResult() async -> ServerEntity? {
        print("ServerQuery: defaultResult() called")
        let servers = loadServers()

        if let firstServer = servers.first {
            print("ServerQuery: Returning default server: \(firstServer.displayString)")
            return firstServer
        } else {
            print("ServerQuery: No servers found, returning nil")
            return nil
        }
    }

    // MARK: - EntityStringQuery Protocol (for search support)

    func entities(matching string: String) async throws -> [ServerEntity] {
        print("ServerQuery: entities(matching:) called with query '\(string)'")
        let allServers = loadServers()

        if string.isEmpty {
            return allServers
        }

        let lowercasedQuery = string.lowercased()
        let result = allServers.filter {
            $0.displayString.lowercased().contains(lowercasedQuery) ||
            $0.ip.contains(string)
        }
        print("ServerQuery: Found \(result.count) matching server(s) for '\(string)'")
        return result
    }
}

// MARK: - ServerEntity Extensions

extension ServerEntity {
    init(fromSharedServer sharedServer: SharedServer) {
        self.id = sharedServer.id.uuidString
        self.serverId = sharedServer.id
        self.displayString = sharedServer.name
        self.ip = sharedServer.ip
        self.port = sharedServer.port
        self.apiKey = sharedServer.apiKey
        self.isConnected = sharedServer.isConnected
        self.isHealthy = sharedServer.isHealthy
    }

    func toSharedServer() -> SharedServer {
        return SharedServer(
            id: self.serverId,
            name: self.displayString,
            ip: self.ip,
            port: self.port,
            apiKey: self.apiKey,
            type: "", // ServerEntity doesn't store type, use empty string as default
            isConnected: self.isConnected,
            isHealthy: self.isHealthy,
            lastConnected: nil,
            uptime: nil
        )
    }
}
