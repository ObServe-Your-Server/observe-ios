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
            URLQueryItem(name: "step", value: "5")
        ]

        networkService.fetch(endpoint: "/memory/total-memory-in-gb", queryItems: queryItems) { [weak self] (result: Result<[MemoryResponse], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let allValues = response.compactMap { Double($0.value) }
                    self?.maxRam = allValues.max()
                    self?.error = nil
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }
}
