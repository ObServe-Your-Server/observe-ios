//
//  WidgetMetricFetcher.swift
//  observeMetricsWidget
//
//  Created by Daniel Schatz on 23.10.25.
//

import Foundation

/// Fetches metrics from server using shared NetworkService
class WidgetMetricFetcher {
    private let networkService: NetworkService

    init(server: SharedServer) {
        self.networkService = NetworkService(
            ip: server.ip,
            port: server.port,
            apiKey: server.apiKey
        )
    }

    // MARK: - Helper Methods

    /// Create query parameters for fetching latest metric value
    private func createLatestValueQueryItems() -> [URLQueryItem] {
        let now = Int(Date().timeIntervalSince1970)
        return [
            URLQueryItem(name: "startTime", value: "\(now - 10)"),  // Last 10 seconds
            URLQueryItem(name: "endTime", value: "\(now)"),
            URLQueryItem(name: "step", value: "5")
        ]
    }

    /// Fetch metric value for the specified type
    func fetchMetric(type: String) async -> Double? {
        return await withCheckedContinuation { continuation in
            switch type {
            case "CPU":
                fetchCPU { continuation.resume(returning: $0) }
            case "RAM":
                fetchRAM { continuation.resume(returning: $0) }
            case "Storage":
                fetchStorage { continuation.resume(returning: $0) }
            case "Network In":
                fetchNetworkIn { continuation.resume(returning: $0) }
            case "Network Out":
                fetchNetworkOut { continuation.resume(returning: $0) }
            default:
                print("WidgetMetricFetcher: Unsupported metric type: \(type)")
                continuation.resume(returning: nil)
            }
        }
    }

    /// Fetch all metrics at once for widget display
    func fetchAllMetrics() async -> [String: Double] {
        async let cpu = fetchMetric(type: "CPU")
        async let ram = fetchMetric(type: "RAM")
        async let storage = fetchMetric(type: "Storage")
        async let networkIn = fetchMetric(type: "Network In")
        async let networkOut = fetchMetric(type: "Network Out")

        var metrics: [String: Double] = [:]

        if let cpuValue = await cpu {
            metrics["CPU"] = cpuValue
        }
        if let ramValue = await ram {
            metrics["RAM"] = ramValue
        }
        if let storageValue = await storage {
            metrics["Storage"] = storageValue
        }
        if let networkInValue = await networkIn {
            metrics["Network In"] = networkInValue
        }
        if let networkOutValue = await networkOut {
            metrics["Network Out"] = networkOutValue
        }

        return metrics
    }

    /// Fetch raw metric values (used/total GB) for RAM and Storage
    func fetchRawMetricValues() async -> [String: [String: Double]] {
        var rawValues: [String: [String: Double]] = [:]
        
        // Fetch RAM raw values
        if let ramValues = await fetchRAMRawValues() {
            rawValues["RAM"] = ramValues
        }
        
        // Fetch Storage raw values
        if let storageValues = await fetchStorageRawValues() {
            rawValues["Storage"] = storageValues
        }
        
        return rawValues
    }

    /// Fetch RAM used and total values in GB
    private func fetchRAMRawValues() async -> [String: Double]? {
        return await withCheckedContinuation { continuation in
            let queryItems = createLatestValueQueryItems()
            let group = DispatchGroup()
            var usedRAM: Double?
            var totalRAM: Double?

            // Fetch used RAM
            group.enter()
            networkService.fetch(endpoint: "/memory/used-in-gb", queryItems: queryItems) { (result: Result<[MemoryResponse], Error>) in
                if case .success(let responses) = result,
                   let latest = responses.last,
                   let value = Double(latest.value) {
                    usedRAM = value
                }
                group.leave()
            }

            // Fetch total RAM
            group.enter()
            networkService.fetch(endpoint: "/memory/total-memory-in-gb", queryItems: queryItems) { (result: Result<[MemoryResponse], Error>) in
                if case .success(let responses) = result,
                   let latest = responses.last,
                   let value = Double(latest.value) {
                    totalRAM = value
                }
                group.leave()
            }

            group.notify(queue: .main) {
                if let used = usedRAM, let total = totalRAM {
                    continuation.resume(returning: ["used": used, "total": total])
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    /// Fetch Storage used and total values in GB
    private func fetchStorageRawValues() async -> [String: Double]? {
        return await withCheckedContinuation { continuation in
            let queryItems = createLatestValueQueryItems()

            networkService.fetch(endpoint: "/disk/disk-stat", queryItems: queryItems) { (result: Result<[DiskStatisticResponse], Error>) in
                switch result {
                case .success(let responses):
                    guard let latest = responses.last,
                          let used = Double(latest.totalUsedSpaceAllDisksInGb),
                          let available = Double(latest.totalAvailableSpaceAllDisksInGb) else {
                        continuation.resume(returning: nil)
                        return
                    }

                    let total = used + available
                    continuation.resume(returning: ["used": used, "total": total])
                case .failure:
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // MARK: - Private Fetch Methods

    private func fetchCPU(completion: @escaping (Double?) -> Void) {
        networkService.fetch(endpoint: "/cpu/current-usage") { (result: Result<CpuUsageResponse, Error>) in
            switch result {
            case .success(let response):
                if let value = Double(response.usageInPercent) {
                    let percentage = value * 100 // Convert fraction (0.0-1.0) to percentage (0-100)
                    print("WidgetMetricFetcher: Fetched CPU = \(percentage)%")
                    completion(percentage)
                } else {
                    print("WidgetMetricFetcher: Failed to parse CPU value: \(response.usageInPercent)")
                    completion(nil)
                }
            case .failure(let error):
                print("WidgetMetricFetcher: Failed to fetch CPU: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    private func fetchRAM(completion: @escaping (Double?) -> Void) {
        let queryItems = createLatestValueQueryItems()

        // Fetch both used and total memory to calculate percentage
        let group = DispatchGroup()
        var usedRAM: Double?
        var totalRAM: Double?

        // Fetch used RAM
        group.enter()
        networkService.fetch(endpoint: "/memory/used-in-gb", queryItems: queryItems) { (result: Result<[MemoryResponse], Error>) in
            if case .success(let responses) = result,
               let latest = responses.last,
               let value = Double(latest.value) {
                usedRAM = value
            }
            group.leave()
        }

        // Fetch total RAM
        group.enter()
        networkService.fetch(endpoint: "/memory/total-memory-in-gb", queryItems: queryItems) { (result: Result<[MemoryResponse], Error>) in
            if case .success(let responses) = result,
               let latest = responses.last,
               let value = Double(latest.value) {
                totalRAM = value
            }
            group.leave()
        }

        group.notify(queue: .main) {
            guard let used = usedRAM, let total = totalRAM, total > 0 else {
                print("WidgetMetricFetcher: Failed to fetch RAM data")
                completion(nil)
                return
            }
            let percentage = (used / total) * 100
            print("WidgetMetricFetcher: Fetched RAM = \(used) GB / \(total) GB = \(percentage)%")
            completion(percentage)
        }
    }

    private func fetchStorage(completion: @escaping (Double?) -> Void) {
        let queryItems = createLatestValueQueryItems()

        networkService.fetch(endpoint: "/disk/disk-stat", queryItems: queryItems) { (result: Result<[DiskStatisticResponse], Error>) in
            switch result {
            case .success(let responses):
                guard let latest = responses.last,
                      let used = Double(latest.totalUsedSpaceAllDisksInGb),
                      let available = Double(latest.totalAvailableSpaceAllDisksInGb) else {
                    print("WidgetMetricFetcher: No Storage data available")
                    completion(nil)
                    return
                }

                let total = used + available
                guard total > 0 else {
                    print("WidgetMetricFetcher: Invalid total storage")
                    completion(nil)
                    return
                }

                let percentage = (used / total) * 100
                print("WidgetMetricFetcher: Fetched Storage = \(used) GB / \(total) GB = \(percentage)%")
                completion(percentage)
            case .failure(let error):
                print("WidgetMetricFetcher: Failed to fetch Storage: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    private func fetchNetworkIn(completion: @escaping (Double?) -> Void) {
        let queryItems = createLatestValueQueryItems()

        networkService.fetch(endpoint: "/network/in", queryItems: queryItems) { (result: Result<[NetworkResponse], Error>) in
            switch result {
            case .success(let responses):
                guard let latest = responses.last else {
                    print("WidgetMetricFetcher: No Network In data available")
                    completion(nil)
                    return
                }

                let value = Double(latest.value) / 1024 // Convert bytes to kB
                print("WidgetMetricFetcher: Fetched Network In = \(value) kB/s")
                completion(value)
            case .failure(let error):
                print("WidgetMetricFetcher: Failed to fetch Network In: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    private func fetchNetworkOut(completion: @escaping (Double?) -> Void) {
        let queryItems = createLatestValueQueryItems()

        networkService.fetch(endpoint: "/network/out", queryItems: queryItems) { (result: Result<[NetworkResponse], Error>) in
            switch result {
            case .success(let responses):
                guard let latest = responses.last else {
                    print("WidgetMetricFetcher: No Network Out data available")
                    completion(nil)
                    return
                }

                let value = Double(latest.value) / 1024 // Convert bytes to kB
                print("WidgetMetricFetcher: Fetched Network Out = \(value) kB/s")
                completion(value)
            case .failure(let error):
                print("WidgetMetricFetcher: Failed to fetch Network Out: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

}
