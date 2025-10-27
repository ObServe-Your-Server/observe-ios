//
//  SharedModels.swift
//  ObServe
//
//  Created by Daniel Schatz on 21.10.25.
//

import Foundation

/// Shared server model for App Group communication between main app and widget
struct SharedServer: Codable, Identifiable {
    let id: UUID
    let name: String
    let ip: String
    let port: String
    let apiKey: String
    let type: String
    let isConnected: Bool
    let isHealthy: Bool
    let lastConnected: Date?
    let uptime: TimeInterval?

    init(id: UUID, name: String, ip: String, port: String, apiKey: String, type: String = "", isConnected: Bool, isHealthy: Bool, lastConnected: Date? = nil, uptime: TimeInterval? = nil) {
        self.id = id
        self.name = name
        self.ip = ip
        self.port = port
        self.apiKey = apiKey
        self.type = type
        self.isConnected = isConnected
        self.isHealthy = isHealthy
        self.lastConnected = lastConnected
        self.uptime = uptime
    }
}

/// Cached metric data for widget display
struct SharedMetricData: Codable {
    let serverId: UUID
    let metricType: String
    let value: Double
    let timestamp: Date
    let history: [Double] // Last 14 values for grid display

    init(serverId: UUID, metricType: String, value: Double, timestamp: Date, history: [Double] = []) {
        self.serverId = serverId
        self.metricType = metricType
        self.value = value
        self.timestamp = timestamp
        self.history = history
    }

    /// Check if cached data is still fresh (less than 2 minutes old)
    var isFresh: Bool {
        return Date().timeIntervalSince(timestamp) < 120
    }

    /// Get age of cached data in seconds
    var ageInSeconds: TimeInterval {
        return Date().timeIntervalSince(timestamp)
    }
}

/// Available metric types
enum MetricType: String, Codable, CaseIterable {
    case cpu = "CPU"
    case ram = "RAM"
    case networkIn = "Network In"
    case networkOut = "Network Out"
    case storage = "Storage"
    case ping = "Ping"

    var displayName: String {
        return self.rawValue
    }
}
