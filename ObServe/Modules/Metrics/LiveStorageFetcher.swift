//
//  LiveStorageFetcher.swift
//  ObServe
//
//  Created by Daniel Schatz on 02.08.25.
//

import Foundation
import Combine

class LiveStorageFetcher: ObservableObject {
    @Published var entries: [StorageEntry] = []
    @Published var error: String?

    private var timer: Timer?
    private let interval: TimeInterval = 3
    private let windowSize: Int = 60
    
    private let ip: String
    private let port: String
    private let networkService: NetworkService
    
    struct StorageEntry: Identifiable {
        let id = UUID()
        let timestamp: Double
        let value: Double
    }
    
    init(ip: String, port: String) {
        self.ip = ip
        self.port = port
        self.networkService = NetworkService(ip: ip, port: port)
    }
    
    func start() {
        fetch()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true, block: { [weak self] _ in
            self?.fetch()
        })
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    func fetch() {
        let now = Int(Date().timeIntervalSince1970)
        let start = now - windowSize
        let end = now
        let endpoint = "/metrics/disk/used-space-in-gb"
        let queryItems = [
            URLQueryItem(name: "startTime", value: "\(start)"),
            URLQueryItem(name: "endTime", value: "\(end)"),
            URLQueryItem(name: "interval", value: "5")
        ]
        networkService.fetch(endpoint: endpoint, queryItems: queryItems) { [weak self] (result: Result<TotalDiskResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let allEntries = response.data.result.flatMap { result in
                        result.values.map { StorageEntry(timestamp: $0.timestamp, value: $0.value) }
                    }
                    self?.entries = allEntries
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }
    
    deinit {
        stop()
    }
}
