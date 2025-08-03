//
//  LiveRamFetcher.swift
//  ObServe
//
//  Created by Daniel Schatz on 02.08.25.
//

import Foundation
import Combine

class LiveRamFetcher: BaseLiveFetcher {
    @Published var entries: [MetricEntry] = []
    
    override func fetch() {
        let queryItems = createTimeWindowQueryItems()
        
        networkService.fetch(endpoint: "/metrics/ram/used-memory-in-gb", queryItems: queryItems) { [weak self] (result: Result<RamResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let entries = self?.processPrometheusResponse(response) ?? []
                    self?.entries = entries
                    self?.error = nil
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }
}
