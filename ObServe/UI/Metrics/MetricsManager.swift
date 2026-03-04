import Foundation
import Combine
import WidgetKit

@MainActor
class MetricsManager: ObservableObject {
    // MARK: - Published Properties
    @Published var error: String?
    @Published var avgCPU: Double = 0.0
    @Published var cpuTemperature: Double?
    @Published var avgRAM: Double = 0.0
    @Published var maxRAM: Double = 0.0
    @Published var avgStorage: Double = 0.0
    @Published var maxStorage: Double = 0.0
    @Published var disks: [DiskPayloadResponse] = []
    @Published var avgNetworkIn: Double = 0.0
    @Published var avgNetworkOut: Double = 0.0
    @Published var uptime: TimeInterval = 0.0
    @Published var ping: Double?
    @Published var uploadSpeed: Double?
    @Published var downloadSpeed: Double?
    @Published var osName: String?
    @Published var kernelVersion: String?
    @Published var cpuName: String?
    @Published var cpuCount: Int64?

    // MARK: - History for charts
    @Published var cpuEntries: [MetricEntry] = []
    @Published var ramEntries: [MetricEntry] = []
    @Published var storageEntries: [MetricEntry] = []
    @Published var networkInEntries: [MetricEntry] = []
    @Published var networkOutEntries: [MetricEntry] = []
    @Published var pingHistory: [PingEntry] = []
    @Published var downloadHistory: [Double] = []
    @Published var uploadHistory: [Double] = []

    struct PingEntry {
        let value: Double? // nil = no data / failed
    }

    private var pollingTimer: Timer?
    private var uptimeTickTimer: Timer?
    private var lastFetchedUptime: TimeInterval?
    private var lastUptimeFetchDate: Date?
    private var cancellables = Set<AnyCancellable>()

    private var lastNetBytesIn: Int64?
    private var lastNetBytesOut: Int64?
    private var lastNetworkSampleTime: Date?

    private let serverId: UUID
    private let machineUUID: UUID
    private let api = WatchTowerAPI.shared
    private let windowSize = 60
    private let pingHistorySize = 10

    // MARK: - Status Callback
    var onStatusChanged: ((MachineStatus) -> Void)?

    // MARK: - Backoff & State
    /// Whether startFetching() has been called and stopFetching() has not yet been called.
    private var isFetchingActive: Bool = false
    /// Number of consecutive fetch failures since the last success.
    private var consecutiveFailures: Int = 0
    /// Maximum backoff delay in seconds.
    private let maxBackoffInterval: TimeInterval = 60

    init(server: ServerModuleItem) {
        self.serverId = server.id
        self.machineUUID = server.machineUUID
        setupPollingIntervalObserver()
        setupNetworkObserver()
    }

    // MARK: - Control Methods

    func startFetching() {
        isFetchingActive = true
        consecutiveFailures = 0
        fetchHistoricalData()
        scheduleNextFetch(delay: 0)
        startUptimeTickTimer()
    }

    func fetchLatestOnce() {
        fetchLatest()
    }

    func stopFetching() {
        isFetchingActive = false
        consecutiveFailures = 0
        lastNetBytesIn = nil
        lastNetBytesOut = nil
        lastNetworkSampleTime = nil
        stopPolling()
        stopUptimeTickTimer()
    }

    // MARK: - Polling

    /// Schedules a one-shot timer that fires after `delay` seconds and calls fetchLatest().
    /// For the normal repeating case (delay == pollingInterval), a repeating timer is used.
    private func scheduleNextFetch(delay: TimeInterval) {
        stopPolling()
        guard isFetchingActive else { return }

        let baseInterval = TimeInterval(SettingsManager.shared.pollingIntervalSeconds)

        if delay == 0 || delay == baseInterval {
            // Normal path: fire immediately (delay == 0) then use repeating timer
            if delay == 0 {
                fetchLatest()
                pollingTimer = Timer.scheduledTimer(withTimeInterval: baseInterval, repeats: true) { [weak self] _ in
                    Task { @MainActor [weak self] in self?.fetchLatest() }
                }
            } else {
                // Exact base interval — just start a clean repeating timer
                pollingTimer = Timer.scheduledTimer(withTimeInterval: baseInterval, repeats: true) { [weak self] _ in
                    Task { @MainActor [weak self] in self?.fetchLatest() }
                }
            }
        } else {
            // Backoff path: one-shot timer, then on success we'll switch back to repeating
            pollingTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in self?.fetchLatest() }
            }
        }
    }

    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    private func startUptimeTickTimer() {
        uptimeTickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.updateUptimeDisplay() }
        }
    }

    private func stopUptimeTickTimer() {
        uptimeTickTimer?.invalidate()
        uptimeTickTimer = nil
    }

    // MARK: - Observers

    private func setupPollingIntervalObserver() {
        SettingsManager.shared.$pollingIntervalSeconds
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, self.isFetchingActive else { return }
                self.consecutiveFailures = 0
                self.scheduleNextFetch(delay: 0)
            }
            .store(in: &cancellables)
    }

    private func setupNetworkObserver() {
        Task { @MainActor in
            NetworkMonitor.shared.$isConnected
                .dropFirst()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isConnected in
                    guard let self = self, self.isFetchingActive else { return }
                    if isConnected {
                        // Connectivity restored — reset backoff and resume immediately
                        self.consecutiveFailures = 0
                        self.scheduleNextFetch(delay: 0)
                    } else {
                        // No connectivity — pause polling to avoid log spam
                        self.stopPolling()
                    }
                }
                .store(in: &self.cancellables)
        }
    }

    // MARK: - Fetch Latest Metric

    private func fetchLatest() {
        // Don't fire requests while offline
        guard NetworkMonitor.shared.isConnected else { return }

        api.fetchLatestMetric(machineUUID: machineUUID) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let metric):
                    self.consecutiveFailures = 0
                    self.processMetric(metric, appendToHistory: true)
                    self.error = nil
                    // Switch back to a clean repeating timer at the base interval
                    if self.isFetchingActive {
                        self.stopPolling()
                        let baseInterval = TimeInterval(SettingsManager.shared.pollingIntervalSeconds)
                        self.pollingTimer = Timer.scheduledTimer(withTimeInterval: baseInterval, repeats: true) { [weak self] _ in
                            Task { @MainActor [weak self] in self?.fetchLatest() }
                        }
                    }
                case .failure(let error):
                    self.error = error.localizedDescription
                    self.consecutiveFailures += 1
                    self.onStatusChanged?(.offline)
                    SharedStorageManager.shared.updateServerStatus(serverId: self.serverId, isConnected: false, machineStatus: .offline, uptime: nil)
                    // Exponential backoff: base * 2^(failures-1), capped at maxBackoffInterval
                    let base = TimeInterval(SettingsManager.shared.pollingIntervalSeconds)
                    let backoff = min(base * pow(2.0, Double(self.consecutiveFailures - 1)), self.maxBackoffInterval)
                    self.scheduleNextFetch(delay: backoff)
                }
            }
        }
    }

    // MARK: - Fetch Historical Data

    private func fetchHistoricalData() {
        api.fetchMetrics(machineUUID: machineUUID, last: 30) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let metrics):
                    self?.cpuEntries = []
                    self?.ramEntries = []
                    self?.storageEntries = []
                    self?.networkInEntries = []
                    self?.networkOutEntries = []

                    for metric in metrics {
                        self?.processMetric(metric, appendToHistory: true)
                    }

                    // Sync historical CPU data to widget
                    if let self = self {
                        let cpuValues = self.cpuEntries.map { $0.value }
                        if !cpuValues.isEmpty {
                            let metricData = SharedMetricData(
                                serverId: self.serverId,
                                metricType: "CPU",
                                value: cpuValues.last ?? 0,
                                timestamp: Date(),
                                history: Array(cpuValues.suffix(30))
                            )
                            SharedStorageManager.shared.saveMetricData(metricData)
                        }

                        let ramValues = self.ramEntries.map { $0.value }
                        if !ramValues.isEmpty, self.maxRAM > 0 {
                            let percentageValues = ramValues.map { ($0 / self.maxRAM) * 100 }
                            let metricData = SharedMetricData(
                                serverId: self.serverId,
                                metricType: "RAM",
                                value: percentageValues.last ?? 0,
                                timestamp: Date(),
                                history: Array(percentageValues.suffix(30))
                            )
                            SharedStorageManager.shared.saveMetricData(metricData)
                        }
                    }
                case .failure(let error):
                    print("Failed to fetch historical metrics: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Process a Single Metric Response

    private func processMetric(_ metric: MachineMetricResponse, appendToHistory: Bool) {
        let timestamp = Date().timeIntervalSince1970

        // CPU
        if let cpuUsage = metric.cpuUsage {
            avgCPU = cpuUsage / 100.0 // Store as fraction (0.0-1.0) to match existing UI expectations
            if appendToHistory {
                cpuEntries.append(MetricEntry(timestamp: timestamp, value: cpuUsage / 100.0))
                if cpuEntries.count > windowSize {
                    cpuEntries = Array(cpuEntries.suffix(windowSize))
                }
            }
            syncMetricToWidget(metricType: "CPU", value: cpuUsage)
        }

        // CPU Temperature
        cpuTemperature = metric.cpuTemperature

        // CPU Hardware Info
        if let name = metric.cpuName { cpuName = name }
        if let count = metric.cpuCount { cpuCount = count }

        // OS Info
        if let os = metric.osName { osName = os }
        if let kernel = metric.kernelVersion { kernelVersion = kernel }

        // RAM (bytes → GB)
        if let memUsed = metric.memUsed {
            let usedGB = Double(memUsed) / (1024.0 * 1024.0 * 1024.0)
            avgRAM = usedGB
            if appendToHistory {
                ramEntries.append(MetricEntry(timestamp: timestamp, value: usedGB))
                if ramEntries.count > windowSize {
                    ramEntries = Array(ramEntries.suffix(windowSize))
                }
            }
            if maxRAM > 0 {
                let percentage = (usedGB / maxRAM) * 100
                syncMetricToWidget(metricType: "RAM", value: percentage)
            }
        }
        if let memTotal = metric.memTotal {
            maxRAM = Double(memTotal) / (1024.0 * 1024.0 * 1024.0)
        }

        // Disks (bytes → GB)
        if let diskData = metric.disks {
            var totalUsed: Int64 = 0
            var totalSize: Int64 = 0
            for disk in diskData {
                totalUsed += disk.used ?? 0
                totalSize += disk.total ?? 0
            }
            let usedGB = Double(totalUsed) / (1024.0 * 1024.0 * 1024.0)
            let totalGB = Double(totalSize) / (1024.0 * 1024.0 * 1024.0)
            avgStorage = usedGB
            maxStorage = totalGB
            disks = diskData
            if appendToHistory {
                storageEntries.append(MetricEntry(timestamp: timestamp, value: usedGB))
                if storageEntries.count > windowSize {
                    storageEntries = Array(storageEntries.suffix(windowSize))
                }
            }
            if maxStorage > 0 {
                let percentage = (usedGB / maxStorage) * 100
                syncMetricToWidget(metricType: "Storage", value: percentage)
            }
        }

        // Network: API sends cumulative bytes totals, so compute bytes/sec from delta
        let now = Date()
        let elapsed = lastNetworkSampleTime.map { now.timeIntervalSince($0) } ?? 0

        if let netIn = metric.netBytesIn {
            if let prev = lastNetBytesIn, elapsed > 0 {
                let rate = Double(max(0, netIn - prev)) / elapsed
                avgNetworkIn = rate
                if appendToHistory {
                    networkInEntries.append(MetricEntry(timestamp: timestamp, value: rate))
                    if networkInEntries.count > windowSize {
                        networkInEntries = Array(networkInEntries.suffix(windowSize))
                    }
                }
                syncMetricToWidget(metricType: "Network In", value: rate)
            }
            lastNetBytesIn = netIn
        }
        if let netOut = metric.netBytesOut {
            if let prev = lastNetBytesOut, elapsed > 0 {
                let rate = Double(max(0, netOut - prev)) / elapsed
                avgNetworkOut = rate
                if appendToHistory {
                    networkOutEntries.append(MetricEntry(timestamp: timestamp, value: rate))
                    if networkOutEntries.count > windowSize {
                        networkOutEntries = Array(networkOutEntries.suffix(windowSize))
                    }
                }
                syncMetricToWidget(metricType: "Network Out", value: rate)
            }
            lastNetBytesOut = netOut
        }
        lastNetworkSampleTime = now

        // Speedtest
        if let speedtest = metric.speedtest {
            ping = speedtest.pingMs
            uploadSpeed = speedtest.uploadMbps
            downloadSpeed = speedtest.downloadMbps
        }
        if appendToHistory {
            let pingValue = metric.speedtest?.pingMs
            pingHistory.append(PingEntry(value: pingValue))
            if pingHistory.count > pingHistorySize {
                pingHistory = Array(pingHistory.suffix(pingHistorySize))
            }

            if let dl = metric.speedtest?.downloadMbps {
                downloadHistory.append(dl)
                if downloadHistory.count > windowSize {
                    downloadHistory = Array(downloadHistory.suffix(windowSize))
                }
            }
            if let ul = metric.speedtest?.uploadMbps {
                uploadHistory.append(ul)
                if uploadHistory.count > windowSize {
                    uploadHistory = Array(uploadHistory.suffix(windowSize))
                }
            }
        }

        // Uptime
        if let uptimeSeconds = metric.uptime {
            uptime = TimeInterval(uptimeSeconds)
            lastFetchedUptime = TimeInterval(uptimeSeconds)
            lastUptimeFetchDate = Date()
        }

        // Compute and emit overall machine status
        let status = MachineStatus.compute(from: metric, isConnected: true)
        onStatusChanged?(status)
        SharedStorageManager.shared.updateServerStatus(
            serverId: serverId,
            isConnected: true,
            machineStatus: status,
            uptime: metric.uptime.map { TimeInterval($0) }
        )
    }

    // MARK: - Uptime Tick

    private func updateUptimeDisplay() {
        guard let lastFetchDate = lastUptimeFetchDate,
              let lastFetched = lastFetchedUptime else { return }
        let elapsed = Date().timeIntervalSince(lastFetchDate)
        uptime = lastFetched + elapsed
    }

    // MARK: - Widget Sync

    private func syncMetricToWidget(metricType: String, value: Double) {
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

    deinit {
        pollingTimer?.invalidate()
        uptimeTickTimer?.invalidate()
    }
}
