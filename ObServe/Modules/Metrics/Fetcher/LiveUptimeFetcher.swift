import Foundation
import Combine

class LiveUptimeFetcher: BaseLiveFetcher {
    @Published var uptime: TimeInterval? // Current uptime in seconds

    private var tickTimer: Timer? // 1-second timer for UI updates
    private var syncTimer: Timer? // 5-minute timer for server sync
    private var lastFetchDate: Date?
    private var lastFetchedUptime: TimeInterval?
    private let syncInterval: TimeInterval = 300 // 5 minutes

    override init(ip: String, port: String, apiKey: String, interval: TimeInterval = 5, windowSize: Int = 60) {
        super.init(ip: ip, port: port, apiKey: apiKey, interval: interval, windowSize: windowSize)
    }

    override func start() {
        // Don't use BaseLiveFetcher's polling timer - we have our own schedule
        // Start the sync timer (every 5 minutes) for server syncing
        startSyncTimer()

        startTickTimer()

        // Fetch immediately on start
        fetch()
    }

    override func stop() {
        stopSyncTimer()
        stopTickTimer()
    }

    override func restart() {
        print("LiveUptimeFetcher: Ignoring restart - maintaining independent 5-minute sync")
    }

    private func startSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            self?.fetch()
        }
    }

    private func stopSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = nil
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
        networkService.fetchPlainValue(endpoint: "/general/uptime-in-seconds", queryItems: []) { [weak self] (result: Result<Int, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let uptimeSeconds):
                    self?.lastFetchedUptime = TimeInterval(uptimeSeconds)
                    self?.lastFetchDate = Date()
                    self?.uptime = TimeInterval(uptimeSeconds)
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
        stopSyncTimer()
        stopTickTimer()
    }
}
