//
//  SharedStorageManager.swift
//  ObServe
//
//  Created by Daniel Schatz on 21.10.25.
//

import Foundation

/// Manager for shared data storage between main app and widget using App Groups
class SharedStorageManager {
    static let shared = SharedStorageManager()

    private let appGroupIdentifier = "group.com.dev.ObServe"
    private let serversKey = "shared_servers"
    private let metricsKey = "shared_metrics"

    private var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupIdentifier)
    }

    private init() {}

    // MARK: - Server Management

    /// Save server list to shared storage
    func saveServers(_ servers: [SharedServer]) {
        guard let defaults = sharedDefaults else {
            print("SharedStorageManager: Failed to access App Group UserDefaults")
            return
        }

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(servers)
            defaults.set(data, forKey: serversKey)
            defaults.synchronize()
            print("SharedStorageManager: Saved \(servers.count) servers to shared storage")
        } catch {
            print("SharedStorageManager: Failed to encode servers: \(error)")
        }
    }

    /// Load server list from shared storage
    func loadServers() -> [SharedServer] {
        guard let defaults = sharedDefaults,
              let data = defaults.data(forKey: serversKey) else {
            print("SharedStorageManager: No servers found in shared storage")
            return []
        }

        do {
            let decoder = JSONDecoder()
            let servers = try decoder.decode([SharedServer].self, from: data)
            print("SharedStorageManager: Loaded \(servers.count) servers from shared storage")
            return servers
        } catch {
            print("SharedStorageManager: Failed to decode servers: \(error)")
            return []
        }
    }

    /// Update a single server's connection status
    func updateServerStatus(serverId: UUID, isConnected: Bool, isHealthy: Bool, uptime: TimeInterval? = nil) {
        var servers = loadServers()

        if let index = servers.firstIndex(where: { $0.id == serverId }) {
            var updatedServer = servers[index]
            updatedServer = SharedServer(
                id: updatedServer.id,
                name: updatedServer.name,
                ip: updatedServer.ip,
                port: updatedServer.port,
                apiKey: updatedServer.apiKey,
                type: updatedServer.type,
                isConnected: isConnected,
                isHealthy: isHealthy,
                lastConnected: isConnected ? Date() : updatedServer.lastConnected,
                uptime: uptime
            )
            servers[index] = updatedServer
            saveServers(servers)
            print("SharedStorageManager: Updated server '\(updatedServer.name)' status - connected: \(isConnected), healthy: \(isHealthy), uptime: \(uptime?.description ?? "nil")")
        }
    }

    /// Get a specific server by ID
    func getServer(byId id: UUID) -> SharedServer? {
        return loadServers().first(where: { $0.id == id })
    }

    // MARK: - Metric Data Management

    /// Save metric data for a specific server and metric type
    func saveMetricData(_ metricData: SharedMetricData) {
        guard let defaults = sharedDefaults else {
            print("SharedStorageManager: Failed to access App Group UserDefaults")
            return
        }

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(metricData)
            let key = metricKey(serverId: metricData.serverId, metricType: metricData.metricType)
            defaults.set(data, forKey: key)
            defaults.synchronize()
            print("SharedStorageManager: Saved metric data for server \(metricData.serverId) - \(metricData.metricType): \(metricData.value)")
        } catch {
            print("SharedStorageManager: Failed to encode metric data: \(error)")
        }
    }

    /// Load metric data for a specific server and metric type
    func loadMetricData(serverId: UUID, metricType: String) -> SharedMetricData? {
        guard let defaults = sharedDefaults else {
            print("SharedStorageManager: Failed to access App Group UserDefaults")
            return nil
        }

        let key = metricKey(serverId: serverId, metricType: metricType)

        guard let data = defaults.data(forKey: key) else {
            print("SharedStorageManager: No cached metric data found for \(metricType)")
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let metricData = try decoder.decode(SharedMetricData.self, from: data)
            print("SharedStorageManager: Loaded cached metric data for \(metricType): \(metricData.value)")
            return metricData
        } catch {
            print("SharedStorageManager: Failed to decode metric data: \(error)")
            return nil
        }
    }

    /// Clear all metric data (useful when server is removed)
    func clearMetricData(serverId: UUID) {
        guard let defaults = sharedDefaults else { return }

        for metricType in MetricType.allCases {
            let key = metricKey(serverId: serverId, metricType: metricType.rawValue)
            defaults.removeObject(forKey: key)
        }
        defaults.synchronize()
        print("SharedStorageManager: Cleared all metric data for server \(serverId)")
    }

    /// Clear all metrics for all servers
    func clearAllMetrics() {
        guard let defaults = sharedDefaults else { return }

        // Get all servers and clear their metrics
        let servers = loadServers()
        for server in servers {
            for metricType in MetricType.allCases {
                let key = metricKey(serverId: server.id, metricType: metricType.rawValue)
                defaults.removeObject(forKey: key)
            }
        }

        defaults.synchronize()
        print("SharedStorageManager: Cleared all metric data for all servers")
    }

    // MARK: - Private Helpers

    private func metricKey(serverId: UUID, metricType: String) -> String {
        return "\(metricsKey)_\(serverId.uuidString)_\(metricType)"
    }
}
