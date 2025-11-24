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

        networkService.fetch(endpoint: "/memory/used-in-gb", queryItems: queryItems) { [weak self] (result: Result<[MemoryResponse], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let entries = response.map {
                        MetricEntry(timestamp: Double($0.unixTime), value: Double($0.value) ?? 0)
                    }
                    self?.entries = entries
                    self?.error = nil
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }

    /// Fetch historical RAM data using the time-range endpoint
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

        networkService.fetch(endpoint: "/memory/used-in-gb", queryItems: queryItems) { (result: Result<[MemoryResponse], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let responses):
                    let entries = responses.map { response in
                        MetricEntry(timestamp: Double(response.unixTime), value: Double(response.value) ?? 0)
                    }
                    completion(entries)
                case .failure(let error):
                    print("Failed to fetch historical RAM data: \(error.localizedDescription)")
                    completion([])
                }
            }
        }
    }
}
