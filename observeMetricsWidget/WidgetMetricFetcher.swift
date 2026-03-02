//
//  WidgetMetricFetcher.swift
//  observeMetricsWidget
//
//  Created by Daniel Schatz on 23.10.25.
//

import Foundation

/// Fetches cached metrics from shared storage for widget display
class WidgetMetricFetcher {
    private let serverId: UUID
    private let storage = SharedStorageManager.shared

    init(server: SharedServer) {
        self.serverId = server.id
    }

    /// Fetch metric value for the specified type from cached data
    func fetchMetric(type: String) async -> Double? {
        let data = storage.loadMetricData(serverId: serverId, metricType: type)
        return data?.value
    }

    /// Fetch all cached metrics for widget display
    func fetchAllMetrics() async -> [String: Double] {
        var metrics: [String: Double] = [:]

        let metricTypes = ["CPU", "RAM", "Storage", "Network In", "Network Out"]
        for type in metricTypes {
            if let data = storage.loadMetricData(serverId: serverId, metricType: type) {
                metrics[type] = data.value
            }
        }

        return metrics
    }

    /// Fetch raw metric values (used/total GB) for RAM and Storage from cached data
    func fetchRawMetricValues() async -> [String: [String: Double]] {
        var rawValues: [String: [String: Double]] = [:]

        if let ramData = storage.loadMetricData(serverId: serverId, metricType: "RAM") {
            // RAM is cached as percentage; raw values not available from cache
            rawValues["RAM"] = ["percentage": ramData.value]
        }

        if let storageData = storage.loadMetricData(serverId: serverId, metricType: "Storage") {
            // Storage is cached as percentage; raw values not available from cache
            rawValues["Storage"] = ["percentage": storageData.value]
        }

        return rawValues
    }
}
