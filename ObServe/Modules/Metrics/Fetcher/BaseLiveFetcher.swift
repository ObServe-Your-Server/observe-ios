//
//  BaseLiveFetcher.swift
//  ObServe
//
//  Created by Daniel Schatz on 03.08.25.
//
import Foundation
import Combine

// Base class for fetchers that need periodic updates
class BaseLiveFetcher: ObservableObject {
    @Published var error: String?

    private var timer: Timer?
    internal let interval: TimeInterval
    internal let windowSize: Int
    internal let networkService: NetworkService

    init(ip: String, port: String, apiKey: String, interval: TimeInterval = 3, windowSize: Int = 60) {
        self.interval = interval
        self.windowSize = windowSize
        self.networkService = NetworkService(ip: ip, port: port, apiKey: apiKey)
    }
    
    func start() {
        fetch()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.fetch()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    // Override in subclasses
    func fetch() {
        print("⚠️ BaseLiveFetcher: Default fetch() called - subclass should override this")
        // Default implementation - subclasses should override
    }
    
    // Helper method to process Prometheus responses
    func processPrometheusResponse(_ response: PrometheusResponse) -> [MetricEntry] {
        return response.data.result.flatMap { result in
            result.values.map { MetricEntry(timestamp: $0.timestamp, value: $0.value) }
        }
    }
    
    // Helper method to create standard time window query items
    func createTimeWindowQueryItems() -> [URLQueryItem] {
        let now = Int(Date().timeIntervalSince1970)
        return [
            URLQueryItem(name: "startTime", value: "\(now - windowSize)"),
            URLQueryItem(name: "endTime", value: "\(now)"),
            URLQueryItem(name: "step", value: "5")
        ]
    }
    
    deinit {
        stop()
    }
}

// Base class for one-time fetchers
class BaseStaticFetcher: ObservableObject {
    @Published var error: String?

    internal let networkService: NetworkService
    private var hasFetched = false

    init(ip: String, port: String, apiKey: String) {
        self.networkService = NetworkService(ip: ip, port: port, apiKey: apiKey)
    }
    
    func fetchIfNeeded() {
        guard !hasFetched else { return }
        hasFetched = true
        fetch()
    }
    
    // Override in subclasses
    func fetch() {
        // Default implementation - subclasses should override
    }
}
