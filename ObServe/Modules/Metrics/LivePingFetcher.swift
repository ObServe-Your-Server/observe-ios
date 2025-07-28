import Foundation
import Combine

class LivePingFetcher: ObservableObject {
    @Published var entries: [PingEntry] = []
    @Published var error: String?

    private var timer: Timer?
    private let interval: TimeInterval = 3
    private let windowSize: Int = 60
    private let networkService: NetworkService
    private let address: String
    
    struct PingEntry: Identifiable {
        let id = UUID()
        let timestamp: Double
        let value: Double
    }
    
    init(ip: String, port: String, address: String = "8.8.8.8") {
        self.networkService = NetworkService(ip: ip, port: port)
        self.address = address
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
    
    private func fetch() {
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
                    self?.entries = self?.entries.filter { $0.timestamp >= now - Double(self?.windowSize ?? 60) } ?? []
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
