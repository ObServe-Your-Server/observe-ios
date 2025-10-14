//
//  LiveStorageFetcher.swift
//  ObServe
//
//  Created by Daniel Schatz on 02.08.25.
//

import Foundation
import Combine

class LiveStorageFetcher: BaseLiveFetcher {
    @Published var entries: [MetricEntry] = []
    
    override func fetch() {
        let queryItems = createTimeWindowQueryItems()

        networkService.fetch(endpoint: "/disk/disk-stat", queryItems: queryItems) { [weak self] (result: Result<[DiskStatisticResponse], Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let entries = response.map {
                        MetricEntry(timestamp: Double($0.unixTime), value: Double($0.totalUsedSpaceAllDisksInGb) ?? 0)
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
