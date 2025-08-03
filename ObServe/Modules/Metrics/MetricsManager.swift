import Foundation
import Combine

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
    
    init(server: ServerModuleItem) {
        // Initialize all fetchers
        self.cpuFetcher = LiveCpuFetcher(ip: server.ip, port: server.port)
        self.ramFetcher = LiveRamFetcher(ip: server.ip, port: server.port)
        self.pingFetcher = LivePingFetcher(ip: server.ip, port: server.port)
        self.storageFetcher = LiveStorageFetcher(ip: server.ip, port: server.port)
        self.diskTotalSizeFetcher = LiveDiskTotalSizeFetcher(ip: server.ip, port: server.port)
        self.totalRamFetcher = LiveTotalRamFetcher(ip: server.ip, port: server.port)
        self.uptimeFetcher = LiveUptimeFetcher(ip: server.ip, port: server.port)
        self.networkFetcher = LiveNetworkFetcher(ip: server.ip, port: server.port)
        
        setupErrorHandling()
        setupDataObservers()
    }
    
    // MARK: - Control Methods
    func startFetching() {
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
    
    // MARK: - Data Observers
    private func setupDataObservers() {
        // CPU observer
        cpuFetcher.$entries
            .sink { [weak self] entries in
                if entries.isEmpty {
                    self?.avgCPU = 0.0
                } else {
                    let sum = entries.map(\.value).reduce(0, +)
                    let avg = sum / Double(entries.count)
                    self?.avgCPU = avg
                }
            }
            .store(in: &cancellables)
        
        // RAM observer
        ramFetcher.$entries
            .sink { [weak self] entries in
                if entries.isEmpty {
                    self?.avgRAM = 0.0
                } else {
                    let sum = entries.map(\.value).reduce(0, +)
                    let avg = sum / Double(entries.count)
                    self?.avgRAM = avg
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
                if entries.isEmpty {
                    self?.avgPing = 0.0
                } else {
                    let sum = entries.map(\.value).reduce(0, +)
                    let avg = sum / Double(entries.count)
                    self?.avgPing = avg
                }
            }
            .store(in: &cancellables)
        
        // Storage observer
        storageFetcher.$entries
            .sink { [weak self] entries in
                if entries.isEmpty {
                    self?.avgStorage = 0.0
                } else {
                    let sum = entries.map(\.value).reduce(0, +)
                    let avg = sum / Double(entries.count)
                    self?.avgStorage = avg
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
                if entries.isEmpty {
                    self?.avgNetworkIn = 0.0
                } else {
                    let sum = entries.map(\.value).reduce(0, +)
                    let avg = sum / Double(entries.count)
                    self?.avgNetworkIn = avg
                }
            }
            .store(in: &cancellables)
        
        // Network OUT observer
        networkFetcher.$outEntries
            .sink { [weak self] entries in
                if entries.isEmpty {
                    self?.avgNetworkOut = 0.0
                } else {
                    let sum = entries.map(\.value).reduce(0, +)
                    let avg = sum / Double(entries.count)
                    self?.avgNetworkOut = avg
                }
            }
            .store(in: &cancellables)
        
        // Uptime observer
        uptimeFetcher.$uptime
            .sink { [weak self] uptime in
                let value = uptime ?? 0.0
                self?.uptime = value
            }
            .store(in: &cancellables)
    }
}
