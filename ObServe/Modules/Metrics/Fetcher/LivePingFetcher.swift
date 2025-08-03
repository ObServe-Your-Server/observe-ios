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
    
    private let address: String
    
    struct PingEntry: Identifiable {
        let id = UUID()
        let timestamp: Double
        let value: Double
    }
    
    init(ip: String, port: String, address: String = "8.8.8.8") {
        self.address = address
        super.init(ip: ip, port: port)
    }
    
    override func fetch() {
        let now = Date().timeIntervalSince1970
        let endpoint = "/metrics/ping/ping-ip-address"
        let queryItems = [
            URLQueryItem(name: "address", value: address),
            URLQueryItem(name: "count", value: "4"),
            URLQueryItem(name: "timeout", value: "3")
        ]
        
        networkService.fetch(endpoint: endpoint, queryItems: queryItems) { [weak self] (result: Result<PingResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let entry = PingEntry(timestamp: now, value: response.avgLatencyMs ?? 0)
                    self?.entries.append(entry)
                    // Keep only entries within windowSize
                    if let windowSize = self?.windowSize {
                        self?.entries = self?.entries.filter { $0.timestamp >= now - Double(windowSize) } ?? []
                    }
                    self?.error = nil
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }
}
