//
//  LiveNetworkFetcher.swift
//  ObServe
//
//  Created by Daniel Schatz on 03.08.25.
//

import Foundation
import Combine

class LiveNetworkFetcher: BaseLiveFetcher {
    @Published var inEntries: [MetricEntry] = []
    @Published var outEntries: [MetricEntry] = []
    
    override func fetch() {
        fetchNetworkIn()
        fetchNetworkOut()
    }
    
    private func fetchNetworkIn() {
        let queryItems = createTimeWindowQueryItems()

        networkService.fetch(endpoint: "/network/in", queryItems: queryItems) { [weak self] (result: Result<[NetworkResponse], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Convert bytes to kilobytes
                    self?.inEntries = response.map {
                        MetricEntry(timestamp: Double($0.unixTime), value: Double($0.value) / 1024)
                    }
                    self?.error = nil
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }

    private func fetchNetworkOut() {
        let queryItems = createTimeWindowQueryItems()

        networkService.fetch(endpoint: "/network/out", queryItems: queryItems) { [weak self] (result: Result<[NetworkResponse], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    // Convert bytes to kilobytes
                    self?.outEntries = response.map {
                        MetricEntry(timestamp: Double($0.unixTime), value: Double($0.value) / 1024)
                    }
                    self?.error = nil
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }
}
