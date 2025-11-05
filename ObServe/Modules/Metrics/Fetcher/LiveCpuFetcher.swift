//
//  LiveMetricsFetcher.swift
//  ObServe
//
//  Created by Daniel Schatz on 28.07.25.
//
import Foundation
import Combine

class LiveCpuFetcher: BaseLiveFetcher {
    @Published var entries: [MetricEntry] = []

    override func fetch() {
        networkService.fetch(endpoint: "/cpu/current-usage", queryItems: []) { [weak self] (result: Result<CpuUsageResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let entry = MetricEntry(timestamp: Double(response.unixTime), value: Double(response.usageInPercent) ?? 0)
                    self?.entries.append(entry)

                    // Keep only the last windowSize entries
                    if let windowSize = self?.windowSize, self?.entries.count ?? 0 > windowSize {
                        self?.entries = Array(self?.entries.suffix(windowSize) ?? [])
                    }

                    self?.error = nil
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }

    /// Fetch historical CPU data using the time-range endpoint
    /// - Parameters:
    ///   - seconds: Number of seconds of history to fetch (default: 150 for 30 points @ 5s intervals)
    ///   - completion: Callback with fetched entries
    func fetchHistoricalData(seconds: Int = 150, completion: @escaping ([MetricEntry]) -> Void) {
        let now = Int(Date().timeIntervalSince1970)
        let queryItems = [
            URLQueryItem(name: "startTime", value: "\(now - seconds)"),
            URLQueryItem(name: "endTime", value: "\(now)"),
            URLQueryItem(name: "step", value: "5")
        ]

        networkService.fetch(endpoint: "/cpu/usage-in-percent-over-time", queryItems: queryItems) { (result: Result<[CpuUsageResponse], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let responses):
                    let entries = responses.map { response in
                        MetricEntry(timestamp: Double(response.unixTime), value: Double(response.usageInPercent) ?? 0)
                    }
                    completion(entries)
                case .failure(let error):
                    print("Failed to fetch historical CPU data: \(error.localizedDescription)")
                    completion([])
                }
            }
        }
    }
}
