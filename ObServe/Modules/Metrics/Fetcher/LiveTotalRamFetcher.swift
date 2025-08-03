//
//  LiveTotalDiskFetcher.swift
//  ObServe
//
//  Created by Daniel Schatz on 02.08.25.
//

import Foundation
import Combine

class LiveTotalRamFetcher: BaseStaticFetcher {
    @Published var maxRam: Double? = nil
    
    override func fetch() {
        let now = Int(Date().timeIntervalSince1970)
        let queryItems = [
            URLQueryItem(name: "startTime", value: "\(now - 60)"),
            URLQueryItem(name: "endTime", value: "\(now)"),
            URLQueryItem(name: "interval", value: "5")
        ]
        
        networkService.fetch(endpoint: "/metrics/ram/total-memory-in-gb", queryItems: queryItems) { [weak self] (result: Result<PrometheusResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let allValues = response.data.result.flatMap { $0.values }
                    self?.maxRam = allValues.map { $0.value }.max()
                    self?.error = nil
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }
}
