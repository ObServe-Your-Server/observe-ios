//
//  LivePingFetcher.swift
//  ObServe
//
//  Created by Daniel Schatz on 02.08.25.
//

import Foundation
import Combine

class LivePingFetcher: BaseLiveFetcher {
    @Published var entries: [PingEntry] = []
    
    struct PingEntry: Identifiable {
        let id = UUID()
        let timestamp: Double
        let value: Double
    }
    
    override func fetch() {
        let now = Date().timeIntervalSince1970

        networkService.fetchPlainValue(endpoint: "/network/ping", queryItems: []) { [weak self] (result: Result<Int, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let pingMs):
                    let entry = PingEntry(timestamp: now, value: Double(pingMs))
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
