import Foundation

@MainActor
class DockerMetricsManager: ObservableObject {
    @Published var containers: [ContainerStatResponse] = []
    @Published var isAvailable: Bool = false

    private let machineUUID: UUID
    private let api = WatchTowerAPI.shared
    private var pollingTimer: Timer?
    private var isFetchingActive = false

    init(machineUUID: UUID) {
        self.machineUUID = machineUUID
    }

    func startFetching() {
        isFetchingActive = true
        fetchLatest()
        let interval = TimeInterval(SettingsManager.shared.pollingIntervalSeconds)
        pollingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.fetchLatest() }
        }
    }

    func stopFetching() {
        isFetchingActive = false
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    private func fetchLatest() {
        guard NetworkMonitor.shared.isConnected else { return }
        let path = "/v1/machines/\(machineUUID.uuidString)/docker-metrics/latest"
        api.fetchRaw(path: path, timeoutInterval: 8) { [weak self] result in
            DispatchQueue.main.async {
                guard let self else { return }
                switch result {
                case let .success(data):
                    do {
                        let response = try JSONDecoder().decode(DockerMetricsResponse.self, from: data)
                        self.containers = response.containers ?? []
                        self.isAvailable = true
                    } catch {
                        // decode error — leave containers unchanged
                    }
                case .failure:
                    break
                }
            }
        }
    }

    deinit {
        pollingTimer?.invalidate()
    }
}
