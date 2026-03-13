import Combine
import Foundation
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
    @Published var machineStatus: MachineStatus = .unknown
    @Published var ping: Double?
    @Published var uploadSpeed: Double?
    @Published var downloadSpeed: Double?
    @Published var osName: String?
    @Published var kernelVersion: String?
    @Published var cpuName: String?
    @Published var cpuCount: Int64?
    @Published var localIp: String?
    @Published var hostname: String?

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
    private var uptimeSyncTimer: Timer?
    private var lastFetchedUptime: TimeInterval?
    private var lastUptimeFetchDate: Date?
    private var cancellables = Set<AnyCancellable>()

    private var lastNetBytesIn: Int64?
    private var lastNetBytesOut: Int64?
    private var lastNetworkSampleTime: Date?

    // MARK: - Logging State

    private let logsManager = ServerLogsManager.shared
    private var previousMachineStatus: MachineStatus?
    private var wasOffline: Bool = false
    private var lastLoggedAt: [String: Date] = [:]
    private let logThrottleInterval: TimeInterval = 60

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
    /// When set, overrides the global SettingsManager polling interval for this instance only.
    var overrideIntervalSeconds: Int?
    /// Number of consecutive fetch failures since the last success.
    private var consecutiveFailures: Int = 0
    /// Maximum backoff delay in seconds.
    private let maxBackoffInterval: TimeInterval = 60

    init(server: ServerModuleItem) {
        serverId = server.id
        machineUUID = server.machineUUID
        // Seed uptime from last known value so the display doesn't jump from 0 on first fetch
        if let cached = SharedStorageManager.shared.getServer(byId: server.id),
           let cachedUptime = cached.uptime, cachedUptime > 0 {
            lastFetchedUptime = cachedUptime
            lastUptimeFetchDate = Date()
            uptime = cachedUptime
        }
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
        startUptimeSyncTimer()
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
        stopUptimeSyncTimer()
    }

    func setOverrideInterval(_ seconds: Int) {
        overrideIntervalSeconds = seconds
        guard isFetchingActive else { return }
        consecutiveFailures = 0
        scheduleNextFetch(delay: 0)
    }

    // MARK: - Polling

    /// Schedules a one-shot timer that fires after `delay` seconds and calls fetchLatest().
    /// For the normal repeating case (delay == pollingInterval), a repeating timer is used.
    private func scheduleNextFetch(delay: TimeInterval) {
        stopPolling()
        guard isFetchingActive else { return }

        let baseInterval = TimeInterval(overrideIntervalSeconds ?? SettingsManager.shared.pollingIntervalSeconds)

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
        uptimeTickTimer?.invalidate()
        uptimeTickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.updateUptimeDisplay() }
        }
    }

    private func stopUptimeTickTimer() {
        uptimeTickTimer?.invalidate()
        uptimeTickTimer = nil
    }

    func startUptimeSyncTimer() {
        uptimeSyncTimer?.invalidate()
        uptimeSyncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.syncUptimeToWidget() }
        }
    }

    func stopUptimeSyncTimer() {
        uptimeSyncTimer?.invalidate()
        uptimeSyncTimer = nil
    }

    // MARK: - Observers

    private func setupPollingIntervalObserver() {
        SettingsManager.shared.$pollingIntervalSeconds
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, isFetchingActive else { return }
                consecutiveFailures = 0
                scheduleNextFetch(delay: 0)
            }
            .store(in: &cancellables)
    }

    private func setupNetworkObserver() {
        Task { @MainActor in
            NetworkMonitor.shared.$isConnected
                .dropFirst()
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isConnected in
                    guard let self, isFetchingActive else { return }
                    if isConnected {
                        // Connectivity restored — reset backoff and resume immediately
                        consecutiveFailures = 0
                        scheduleNextFetch(delay: 0)
                    } else {
                        // No connectivity — pause polling to avoid log spam
                        stopPolling()
                    }
                }
                .store(in: &self.cancellables)
        }
    }

    // MARK: - Fetch Latest Metric

    private func fetchLatest() {
        // Don't fire requests while offline
        guard NetworkMonitor.shared.isConnected else { return }

        api.fetchLatestMetric(machineUUID: machineUUID, timeoutInterval: 8) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case let .success(metric):
                    self.consecutiveFailures = 0
                    if self.wasOffline {
                        self.logsManager.addLog(
                            serverId: self.serverId,
                            severity: .info,
                            title: "SERVER CAME BACK ONLINE"
                        )
                        self.wasOffline = false
                    }
                    self.processMetric(metric, appendToHistory: true)
                    self.error = nil
                    // Switch back to a clean repeating timer at the base interval
                    if self.isFetchingActive {
                        self.stopPolling()
                        let baseInterval = TimeInterval(self.overrideIntervalSeconds ?? SettingsManager.shared
                            .pollingIntervalSeconds)
                        self.pollingTimer = Timer
                            .scheduledTimer(withTimeInterval: baseInterval, repeats: true) { [weak self] _ in
                                Task { @MainActor [weak self] in self?.fetchLatest() }
                            }
                    }
                case let .failure(error):
                    self.error = error.localizedDescription
                    self.consecutiveFailures += 1
                    // Only declare offline after 3 consecutive failures to tolerate
                    // transient timeouts (e.g. server under heavy CPU load).
                    let offlineThreshold = 3
                    if self.consecutiveFailures >= offlineThreshold {
                        if !self.wasOffline {
                            self.logsManager.addLog(
                                serverId: self.serverId,
                                severity: .critical,
                                title: "SERVER WENT OFFLINE",
                                detail: error.localizedDescription
                            )
                            self.wasOffline = true
                        }
                        self.machineStatus = .offline
                        self.onStatusChanged?(.offline)
                        SharedStorageManager.shared.updateServerStatus(
                            serverId: self.serverId,
                            isConnected: false,
                            machineStatus: .offline,
                            uptime: nil
                        )
                    }
                    // Exponential backoff: base * 2^(failures-1), capped at maxBackoffInterval
                    let base = TimeInterval(self.overrideIntervalSeconds ?? SettingsManager.shared
                        .pollingIntervalSeconds)
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
                case let .success(metrics):
                    self?.cpuEntries = []
                    self?.ramEntries = []
                    self?.storageEntries = []
                    self?.networkInEntries = []
                    self?.networkOutEntries = []

                    for metric in metrics {
                        self?.processMetric(metric, appendToHistory: true, isHistorical: true)
                    }

                    // Sync historical CPU data to widget
                    if let self {
                        let cpuValues = self.cpuEntries.map(\.value)
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

                        let ramValues = self.ramEntries.map(\.value)
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
                case let .failure(error):
                    print("Failed to fetch historical metrics: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Process a Single Metric Response

    // swiftlint:disable:next cyclomatic_complexity
    private func processMetric(_ metric: MachineMetricResponse, appendToHistory: Bool, isHistorical: Bool = false) {
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
        if let name = metric.cpuName { cpuName = Self.cleanCPUName(name) }
        if let count = metric.cpuCount { cpuCount = count }

        // OS Info
        if let os = metric.osName { osName = os }
        if let kernel = metric.kernelVersion { kernelVersion = kernel }

        // Network Info
        if let ip = metric.localIp { localIp = ip }
        if let h = metric.hostname { hostname = h }

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

        // Network: prefer server-provided per-second rates; fall back to computing from cumulative deltas
        let now = Date()
        let elapsed = lastNetworkSampleTime.map { now.timeIntervalSince($0) } ?? 0

        if let serverRate = metric.netBytesInPerSecond {
            let rate = Double(serverRate)
            avgNetworkIn = rate
            if appendToHistory {
                networkInEntries.append(MetricEntry(timestamp: timestamp, value: rate))
                if networkInEntries.count > windowSize {
                    networkInEntries = Array(networkInEntries.suffix(windowSize))
                }
            }
            syncMetricToWidget(metricType: "Network In", value: rate)
        } else if let netIn = metric.netBytesIn {
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

        if let serverRate = metric.netBytesOutPerSecond {
            let rate = Double(serverRate)
            avgNetworkOut = rate
            if appendToHistory {
                networkOutEntries.append(MetricEntry(timestamp: timestamp, value: rate))
                if networkOutEntries.count > windowSize {
                    networkOutEntries = Array(networkOutEntries.suffix(windowSize))
                }
            }
            syncMetricToWidget(metricType: "Network Out", value: rate)
        } else if let netOut = metric.netBytesOut {
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

        // Uptime: only update the anchor from live fetches; skip historical data to avoid a stale anchor.
        // Only accept a new server value if it's >= the current displayed uptime — this prevents the
        // label from jumping backwards when the backend delivers a stale/out-of-sync snapshot.
        if !isHistorical, let uptimeSeconds = metric.uptime {
            let newUptime = TimeInterval(uptimeSeconds)
            if newUptime >= uptime {
                lastFetchedUptime = newUptime
                lastUptimeFetchDate = Date()
            }
        }

        // Compute and emit overall machine status
        let status = MachineStatus.compute(from: metric, isConnected: true)
        machineStatus = status
        onStatusChanged?(status)
        SharedStorageManager.shared.updateServerStatus(
            serverId: serverId,
            isConnected: true,
            machineStatus: status
        )

        if !isHistorical {
            logMetricAlerts(from: metric)
            logStatusTransition(from: previousMachineStatus, to: status)
        }
        previousMachineStatus = status
    }

    // MARK: - Logging Helpers

    private func shouldLog(key: String) -> Bool {
        let now = Date()
        if let last = lastLoggedAt[key], now.timeIntervalSince(last) < logThrottleInterval {
            return false
        }
        lastLoggedAt[key] = now
        return true
    }

    private func logMetricAlerts(from metric: MachineMetricResponse) {
        if let cpu = metric.cpuUsage {
            if cpu >= 95, shouldLog(key: "cpu_critical") {
                logsManager.addLog(
                    serverId: serverId,
                    severity: .critical,
                    title: "CPU CRITICAL",
                    detail: String(format: "CPU usage at %.1f%%", cpu)
                )
            } else if cpu >= 80, shouldLog(key: "cpu_warning") {
                logsManager.addLog(
                    serverId: serverId,
                    severity: .warning,
                    title: "CPU HIGH",
                    detail: String(format: "CPU usage at %.1f%%", cpu)
                )
            }
        }

        if let temp = metric.cpuTemperature {
            if temp >= 85, shouldLog(key: "temp_critical") {
                logsManager.addLog(
                    serverId: serverId,
                    severity: .critical,
                    title: "CPU TEMPERATURE CRITICAL",
                    detail: String(format: "%.1f°C", temp)
                )
            } else if temp >= 75, shouldLog(key: "temp_warning") {
                logsManager.addLog(
                    serverId: serverId,
                    severity: .warning,
                    title: "CPU TEMPERATURE HIGH",
                    detail: String(format: "%.1f°C", temp)
                )
            }
        }

        if let used = metric.memUsed, let total = metric.memTotal, total > 0 {
            let pct = Double(used) / Double(total) * 100
            if pct >= 95, shouldLog(key: "mem_critical") {
                logsManager.addLog(
                    serverId: serverId,
                    severity: .critical,
                    title: "MEMORY CRITICAL",
                    detail: String(format: "Memory at %.1f%%", pct)
                )
            } else if pct >= 85, shouldLog(key: "mem_warning") {
                logsManager.addLog(
                    serverId: serverId,
                    severity: .warning,
                    title: "MEMORY HIGH",
                    detail: String(format: "Memory at %.1f%%", pct)
                )
            }
        }

        for disk in metric.disks ?? [] {
            if let used = disk.used, let total = disk.total, total > 0 {
                let pct = Double(used) / Double(total) * 100
                let name = (disk.name ?? "Disk").replacingOccurrences(of: "/dev/", with: "")
                let keyBase = "disk_\(name)"
                if pct >= 95, shouldLog(key: "\(keyBase)_critical") {
                    logsManager.addLog(
                        serverId: serverId,
                        severity: .critical,
                        title: "DISK CRITICAL",
                        detail: String(format: "%@ at %.1f%%", name, pct)
                    )
                } else if pct >= 85, shouldLog(key: "\(keyBase)_warning") {
                    logsManager.addLog(
                        serverId: serverId,
                        severity: .warning,
                        title: "DISK HIGH",
                        detail: String(format: "%@ at %.1f%%", name, pct)
                    )
                }
            }
        }
    }

    private func logStatusTransition(from previous: MachineStatus?, to current: MachineStatus) {
        guard let previous, previous != current, previous != .unknown else { return }
        // Offline transitions are handled in the fetch failure path
        guard current != .offline else { return }

        let severity: LogSeverity
        let title: String

        switch current {
        case .critical:
            severity = .critical
            title = "STATUS CHANGED TO CRITICAL"
        case .warning:
            severity = .warning
            title = "STATUS CHANGED TO WARNING"
        case .healthy:
            severity = .info
            title = "STATUS RETURNED TO HEALTHY"
        default:
            severity = .info
            title = "STATUS CHANGED TO \(current.rawValue.uppercased())"
        }

        logsManager.addLog(
            serverId: serverId,
            severity: severity,
            title: title,
            detail: "Previous: \(previous.rawValue)"
        )
    }

    // MARK: - Uptime Tick

    private func updateUptimeDisplay() {
        guard let lastFetchDate = lastUptimeFetchDate,
              let lastFetched = lastFetchedUptime else { return }
        let elapsed = Date().timeIntervalSince(lastFetchDate)
        uptime = lastFetched + elapsed
    }

    private func syncUptimeToWidget() {
        guard let lastFetchDate = lastUptimeFetchDate,
              let lastFetched = lastFetchedUptime else { return }
        let currentUptime = lastFetched + Date().timeIntervalSince(lastFetchDate)
        SharedStorageManager.shared.updateServerStatus(
            serverId: serverId,
            isConnected: true,
            machineStatus: previousMachineStatus ?? .unknown,
            uptime: currentUptime
        )
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
        uptimeSyncTimer?.invalidate()
    }

    private static func cleanCPUName(_ name: String) -> String {
        var result = name
        // Remove legal symbols
        result = result.replacingOccurrences(of: "(R)", with: "", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "(TM)", with: "", options: .caseInsensitive)
        result = result.replacingOccurrences(of: "(C)", with: "", options: .caseInsensitive)
        // Remove redundant "CPU" label
        result = result.replacingOccurrences(of: " CPU", with: "", options: .caseInsensitive)
        // Remove frequency suffix like "@ 3.10GHz"
        if let range = result.range(of: #"\s*@\s*[\d.]+\s*[GMg][Hh][Zz]"#, options: .regularExpression) {
            result.removeSubrange(range)
        }
        // Collapse multiple spaces
        result = result.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: .regularExpression)
        return result.trimmingCharacters(in: .whitespaces)
    }
}
