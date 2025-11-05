import Foundation
import Combine
import WidgetKit

class MetricsManager: ObservableObject {
    // MARK: - Published Properties
    @Published var error: String?
    @Published var avgCPU: Double = 0.0
    @Published var avgRAM: Double = 0.0
    @Published var maxRAM: Double = 0.0
    @Published var avgPing: Double = 0.0
    @Published var avgStorage: Double = 0.0
    @Published var maxStorage: Double = 0.0
    @Published var avgNetworkIn: Double = 0.0
    @Published var avgNetworkOut: Double = 0.0
    @Published var uptime: TimeInterval = 0.0

    // MARK: - Fetchers
    let cpuFetcher: LiveCpuFetcher
    let ramFetcher: LiveRamFetcher
    let pingFetcher: LivePingFetcher
    let storageFetcher: LiveStorageFetcher
    let diskTotalSizeFetcher: LiveDiskTotalSizeFetcher
    let uptimeFetcher: LiveUptimeFetcher
    let totalRamFetcher: LiveTotalRamFetcher
    let networkFetcher: LiveNetworkFetcher

    private var cancellables = Set<AnyCancellable>()
    private let serverId: UUID

    init(server: ServerModuleItem) {
        self.serverId = server.id

        // Initialize all fetchers
        self.cpuFetcher = LiveCpuFetcher(ip: server.ip, port: server.port, apiKey: server.apiKey)
        self.ramFetcher = LiveRamFetcher(ip: server.ip, port: server.port, apiKey: server.apiKey)
        self.pingFetcher = LivePingFetcher(ip: server.ip, port: server.port, apiKey: server.apiKey)
        self.storageFetcher = LiveStorageFetcher(ip: server.ip, port: server.port, apiKey: server.apiKey)
        self.diskTotalSizeFetcher = LiveDiskTotalSizeFetcher(ip: server.ip, port: server.port, apiKey: server.apiKey)
        self.totalRamFetcher = LiveTotalRamFetcher(ip: server.ip, port: server.port, apiKey: server.apiKey)
        self.uptimeFetcher = LiveUptimeFetcher(ip: server.ip, port: server.port, apiKey: server.apiKey)
        self.networkFetcher = LiveNetworkFetcher(ip: server.ip, port: server.port, apiKey: server.apiKey)

        setupErrorHandling()
        setupDataObservers()
    }
    
    // MARK: - Control Methods
    func startFetching() {
        fetchInitialHistoricalData()
        startLiveFetchers()
        startStaticFetchers()
    }
    
    func stopFetching() {
        stopLiveFetchers()
    }
    
    private func startLiveFetchers() {
        cpuFetcher.start()
        ramFetcher.start()
        pingFetcher.start()
        storageFetcher.start()
        networkFetcher.start()
        uptimeFetcher.start()
    }
    
    private func startStaticFetchers() {
        diskTotalSizeFetcher.fetchIfNeeded()
        totalRamFetcher.fetchIfNeeded()
    }
    
    private func stopLiveFetchers() {
        cpuFetcher.stop()
        ramFetcher.stop()
        pingFetcher.stop()
        storageFetcher.stop()
        networkFetcher.stop()
        uptimeFetcher.stop()
    }
    
    // MARK: - Error Handling
    private func setupErrorHandling() {
        // Monitor each fetcher's error property individually
        cpuFetcher.$error
            .compactMap { $0 }
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
        
        ramFetcher.$error
            .compactMap { $0 }
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
        
        pingFetcher.$error
            .compactMap { $0 }
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
        
        storageFetcher.$error
            .compactMap { $0 }
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
        
        networkFetcher.$error
            .compactMap { $0 }
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
        
        uptimeFetcher.$error
            .compactMap { $0 }
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
        
        diskTotalSizeFetcher.$error
            .compactMap { $0 }
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
        
        totalRamFetcher.$error
            .compactMap { $0 }
            .assign(to: \.error, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Historical Data Initialization

    /// Fetch historical data on startup to prefill cache with 150 seconds (30 points @ 5s intervals)
    private func fetchInitialHistoricalData() {
        // Fetch CPU historical data
        cpuFetcher.fetchHistoricalData(seconds: 150) { [weak self] entries in
            guard let self = self else { return }

            // Convert entries to percentage values and sync to widget cache
            let percentageValues = entries.map { $0.value * 100 }

            // Save as initial history
            if !percentageValues.isEmpty {
                let metricData = SharedMetricData(
                    serverId: self.serverId,
                    metricType: "CPU",
                    value: percentageValues.last ?? 0,
                    timestamp: Date(),
                    history: Array(percentageValues.suffix(30))  // Keep last 30 values
                )
                SharedStorageManager.shared.saveMetricData(metricData)
            }
        }

        // Fetch RAM historical data
        ramFetcher.fetchHistoricalData(seconds: 150) { [weak self] entries in
            guard let self = self else { return }

            // Convert entries to percentage values (if maxRAM is available)
            if self.maxRAM > 0 {
                let percentageValues = entries.map { ($0.value / self.maxRAM) * 100 }

                // Save as initial history
                if !percentageValues.isEmpty {
                    let metricData = SharedMetricData(
                        serverId: self.serverId,
                        metricType: "RAM",
                        value: percentageValues.last ?? 0,
                        timestamp: Date(),
                        history: Array(percentageValues.suffix(30))  // Keep last 30 values
                    )
                    SharedStorageManager.shared.saveMetricData(metricData)
                }
            }
        }
    }

    // MARK: - Widget Sync

    /// Sync metric data to shared storage for widget access
    private func syncMetricToWidget(metricType: String, value: Double) {
        guard let serverId = self.serverId as UUID? else { return }

        // Load existing history
        let cachedMetric = SharedStorageManager.shared.loadMetricData(
            serverId: serverId,
            metricType: metricType
        )

        var history = cachedMetric?.history ?? []
        history.append(value)
        if history.count > 30 {
            history.removeFirst()
        }

        let metricData = SharedMetricData(
            serverId: serverId,
            metricType: metricType,
            value: value,
            timestamp: Date(),
            history: history
        )

        SharedStorageManager.shared.saveMetricData(metricData)
    }

    // MARK: - Data Observers
    private func setupDataObservers() {
        // CPU observer
        cpuFetcher.$entries
            .sink { [weak self] entries in
                guard let self = self else { return }
                if entries.isEmpty {
                    self.avgCPU = 0.0
                } else {
                    let test = entries.last?.value ?? 0.0
                    self.avgCPU = test
                    // TODO: Fixen
                    //let sum = entries.map(\.value).reduce(0, +)
                    //let avg = sum / Double(entries.count)
                    //self.avgCPU = avg

                    // Sync to widget (convert fraction to percentage)
                    self.syncMetricToWidget(metricType: "CPU", value: test * 100)
                }
            }
            .store(in: &cancellables)
        
        // RAM observer
        ramFetcher.$entries
            .sink { [weak self] entries in
                guard let self = self else { return }
                if entries.isEmpty {
                    self.avgRAM = 0.0
                } else {
                    let test = entries.last?.value ?? 0.0
                    self.avgRAM = test
// TODO: Fixen
//                    let sum = entries.map(\.value).reduce(0, +)
//                    let avg = sum / Double(entries.count)
//                    self.avgRAM = avg

                    // Sync percentage to widget (not raw GB value)
                    if self.maxRAM > 0 {
                        let percentage = (test / self.maxRAM) * 100
                        self.syncMetricToWidget(metricType: "RAM", value: percentage)
                    }
                }
            }
            .store(in: &cancellables)
        
        // Total RAM observer
        totalRamFetcher.$maxRam
            .sink { [weak self] maxRam in
                let value = maxRam ?? 0.0
                self?.maxRAM = value
            }
            .store(in: &cancellables)
        
        // Ping observer
        pingFetcher.$entries
            .sink { [weak self] entries in
                guard let self = self else { return }
                if entries.isEmpty {
                    self.avgPing = 0.0
                } else {
                    let sum = entries.map(\.value).reduce(0, +)
                    let avg = sum / Double(entries.count)
                    self.avgPing = avg

                    // Sync to widget (use latest value)
                    if let latestValue = entries.last?.value {
                        self.syncMetricToWidget(metricType: "Ping", value: latestValue)
                    }
                }
            }
            .store(in: &cancellables)
        
        // Storage observer
        storageFetcher.$entries
            .sink { [weak self] entries in
                guard let self = self else { return }
                if entries.isEmpty {
                    self.avgStorage = 0.0
                } else {
                    let sum = entries.map(\.value).reduce(0, +)
                    let avg = sum / Double(entries.count)
                    self.avgStorage = avg

                    // Sync percentage to widget (not raw GB value)
                    if let latestValue = entries.last?.value, self.maxStorage > 0 {
                        let percentage = (latestValue / self.maxStorage) * 100
                        self.syncMetricToWidget(metricType: "Storage", value: percentage)
                    }
                }
            }
            .store(in: &cancellables)
        
        // Max Storage observer
        diskTotalSizeFetcher.$maxDiskSize
            .sink { [weak self] maxDiskSize in
                let value = maxDiskSize ?? 0.0
                self?.maxStorage = value
            }
            .store(in: &cancellables)
        
        // Network IN observer
        networkFetcher.$inEntries
            .sink { [weak self] entries in
                guard let self = self else { return }
                if entries.isEmpty {
                    self.avgNetworkIn = 0.0
                } else {
                    let test = entries.last?.value ?? 0.0

                    // Round to match display formatting (0 decimal places)
                    let roundedValue = round(test)
                    self.avgNetworkIn = roundedValue

                    // TODO: Fixen
                    //let sum = entries.map(\.value).reduce(0, +)
                    //let avg = sum / Double(entries.count)
                    //self.avgNetworkIn = avg

                    // Debug logging
                    print("DEBUG: Network IN - raw: \(test), rounded: \(roundedValue), avgNetworkIn: \(self.avgNetworkIn)")

                    // Sync to widget (use same rounded value as main app displays)
                    self.syncMetricToWidget(metricType: "Network In", value: roundedValue)
                }
            }
            .store(in: &cancellables)

        // Network OUT observer
        networkFetcher.$outEntries
            .sink { [weak self] entries in
                guard let self = self else { return }
                if entries.isEmpty {
                    self.avgNetworkOut = 0.0
                } else {
                    let test = entries.last?.value ?? 0.0
                    
                    // Round to match display formatting (0 decimal places)
                    let roundedValue = round(test)
                    self.avgNetworkOut = roundedValue
                    
                    // TODO: Fixen
                    //let avg = sum / Double(entries.count)
                    //self.avgNetworkOut = avg

                    // Debug logging
                    print("DEBUG: Network OUT - raw: \(test), rounded: \(roundedValue), avgNetworkOut: \(self.avgNetworkOut)")
                    
                    // Sync to widget (use same rounded value as main app displays)
                    self.syncMetricToWidget(metricType: "Network Out", value: roundedValue)
                }
            }
            .store(in: &cancellables)
        
        // Uptime observer
        uptimeFetcher.$uptime
            .sink { [weak self] uptime in
                guard let self = self else { return }
                let value = uptime ?? 0.0
                self.uptime = value

                // Sync uptime to widget
                if let serverId = self.serverId as UUID? {
                    SharedStorageManager.shared.updateServerStatus(
                        serverId: serverId,
                        isConnected: true,
                        isHealthy: true,
                        uptime: uptime
                    )
                }
            }
            .store(in: &cancellables)
    }
}
