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
}
