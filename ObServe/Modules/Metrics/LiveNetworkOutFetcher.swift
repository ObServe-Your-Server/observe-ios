import Foundation
import Combine

class LiveNetworkOutFetcher: ObservableObject {
    @Published var entries: [NetworkOutEntry] = []
    @Published var error: String?

    private var timer: Timer?
    private let interval: TimeInterval = 3
    private let windowSize: Int = 60
    
    private let ip: String
    private let port: String
    private let networkService: NetworkService
    
    struct NetworkOutEntry: Identifiable {
        let id = UUID()
        let timestamp: Double
        let value: Double // in kBps
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
    
    private func fetch() {
        let now = Int(Date().timeIntervalSince1970)
        let start = now - windowSize
        let end = now
        let endpoint = "/metrics/network/out"
        let queryItems = [
            URLQueryItem(name: "startTime", value: "\(start)"),
            URLQueryItem(name: "endTime", value: "\(end)"),
            URLQueryItem(name: "interval", value: "5")
        ]
        networkService.fetch(endpoint: endpoint, queryItems: queryItems) { [weak self] (result: Result<NetworkOutResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let allEntries = response.data.result.flatMap { result in
                        result.values.map {
                            // Convert bytes/sec to kBps: (bytes/sec) / 1024
                            NetworkOutEntry(timestamp: $0.timestamp, value: $0.value / 1024)
                        }
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
