import Foundation
import Combine

class LiveUptimeFetcher: BaseLiveFetcher {
    @Published var uptime: TimeInterval? // Current uptime in seconds
    
    private var tickTimer: Timer? // 1-second timer for UI updates
    private var lastFetchDate: Date?
    private var lastFetchedUptime: TimeInterval?
    
    override init(ip: String, port: String, interval: TimeInterval = 300, windowSize: Int = 60) {
        // Set fetch interval to 5 minutes (300 seconds)
        super.init(ip: ip, port: port, interval: interval, windowSize: windowSize)
    }
    
    override func start() {
        // Start the network fetch timer (every 5 minutes)
        super.start()
        
        // Start the UI update timer (every 1 second)
        startTickTimer()
    }
    
    override func stop() {
        super.stop()
        stopTickTimer()
    }
    
    private func startTickTimer() {
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateUptimeDisplay()
        }
    }
    
    private func stopTickTimer() {
        tickTimer?.invalidate()
        tickTimer = nil
    }
    
    override func fetch() {
        let now = Int(Date().timeIntervalSince1970)
        let queryItems = [
            URLQueryItem(name: "startTime", value: "\(now - 10)"),
            URLQueryItem(name: "endTime", value: "\(now)")
        ]
        
        networkService.fetch(endpoint: "/metrics/uptime/in-seconds", queryItems: queryItems) { [weak self] (result: Result<PrometheusResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    if let value = response.data.result.first?.values.last?.value {
                        self?.lastFetchedUptime = value
                        self?.lastFetchDate = Date()
                        self?.uptime = value
                    }
                    self?.error = nil
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }
    
    private func updateUptimeDisplay() {
        guard let lastFetchDate = lastFetchDate,
              let lastFetchedUptime = lastFetchedUptime else {
            return
        }
        
        // Calculate elapsed time since last fetch and add it to the last fetched uptime
        let elapsedSinceLastFetch = Date().timeIntervalSince(lastFetchDate)
        uptime = lastFetchedUptime + elapsedSinceLastFetch
    }
    
    deinit {
        stopTickTimer()
    }
}
