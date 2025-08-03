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
        let queryItems = createTimeWindowQueryItems()
        
        networkService.fetch(endpoint: "/metrics/cpu/usage-in-percent", queryItems: queryItems) { [weak self] (result: Result<CpuResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let entries = response.metrics.map {
                        MetricEntry(timestamp: $0.timestamp, value: $0.value)
                    }
                    self?.entries = entries
                    self?.error = nil
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }
}
