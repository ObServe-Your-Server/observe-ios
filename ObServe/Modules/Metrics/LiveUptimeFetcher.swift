import Foundation
import Combine

class LiveUptimeFetcher: ObservableObject {
    @Published var uptime: TimeInterval? // seconds
    @Published var error: String?

    private var fetchTimer: Timer?
    private var tickTimer: Timer?
    private let fetchInterval: TimeInterval = 300 // 5 minutes
    private let endpoint = "/metrics/uptime/in-seconds"
    private let ip: String
    private let port: String
    private let networkService: NetworkService
    private var lastFetchDate: Date?
    private var lastFetchedUptime: TimeInterval?

    init(ip: String, port: String) {
        self.ip = ip
        self.port = port
        self.networkService = NetworkService(ip: ip, port: port)
    }

    func start() {
        fetch()
        fetchTimer = Timer.scheduledTimer(withTimeInterval: fetchInterval, repeats: true) { [weak self] _ in
            self?.fetch()
        }
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func stop() {
        fetchTimer?.invalidate()
        fetchTimer = nil
        tickTimer?.invalidate()
        tickTimer = nil
    }

    private func fetch() {
        let now = Int(Date().timeIntervalSince1970)
        let start = now - 10
        let end = now
        let queryItems = [
            URLQueryItem(name: "startTime", value: "\(start)"),
            URLQueryItem(name: "endTime", value: "\(end)")
        ]
        networkService.fetch(endpoint: endpoint, queryItems: queryItems) { [weak self] (result: Result<UptimeResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if let value = response.data.result.first?.values.last?.value {
                        self?.lastFetchedUptime = value
                        self?.lastFetchDate = Date()
                        self?.uptime = value
                    }
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }

    private func tick() {
        guard let lastFetchDate = lastFetchDate, let lastFetchedUptime = lastFetchedUptime else { return }
        let elapsed = Date().timeIntervalSince(lastFetchDate)
        self.uptime = lastFetchedUptime + elapsed
    }

    deinit {
        stop()
    }
}
