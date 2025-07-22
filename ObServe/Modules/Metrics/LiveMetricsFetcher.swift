//
//  LiveMetricsFetcher.swift
//  ObServe
//
//  Created by Daniel Schatz on 28.07.25.
//

import Foundation
import Combine

class LiveMetricsFetcher: ObservableObject {
    @Published var entries: [MetricResponse.Entry] = []
    @Published var error: String?

    private var timer: Timer?
    private let interval: TimeInterval = 3
    private let windowSize: Int = 60  // seconds to look back

    private let ip: String
    private let port: String
    private var backendURL: String { "http://\(ip):\(port)/v1/metrics/cpu/usage-in-percent" }

    init(ip: String, port: String) {
        self.ip = ip
        self.port = port
    }
    
    func start() {
        fetch() // initial load
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.fetch()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func fetch() {
        let now = Int(Date().timeIntervalSince1970)
        let start = now - windowSize
        let end = now

        let urlStr = "\(backendURL)?startTime=\(start)&endTime=\(end)&interval=5"
        guard let url = URL(string: urlStr) else {
            self.error = "Invalid URL"
            return
        }

        URLSession.shared.dataTask(with: url) { data, _, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }

                guard let data = data else {
                    self.error = "No data"
                    return
                }

                do {
                    let response = try JSONDecoder().decode(MetricResponse.self, from: data)
                    self.entries = response.metrics
                } catch {
                    self.error = "Decode error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    deinit {
        stop()
    }
}
