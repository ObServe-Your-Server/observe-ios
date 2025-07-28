import Foundation
import Combine

class LiveTotalRamFetcher: ObservableObject {
    @Published var maxRam: Double? = nil
    @Published var error: String?
    private var hasFetched = false
    private let networkService: NetworkService
    init(ip: String, port: String) {
        self.networkService = NetworkService(ip: ip, port: port)
    }
    func fetchIfNeeded() {
        guard !hasFetched else { return }
        hasFetched = true
        fetch()
    }
    func fetch() {
        let now = Int(Date().timeIntervalSince1970)
        let start = now - 60
        let end = now
        let queryItems = [
            URLQueryItem(name: "startTime", value: "\(start)"),
            URLQueryItem(name: "endTime", value: "\(end)"),
            URLQueryItem(name: "interval", value: "5")
        ]
        networkService.fetch(endpoint: "/metrics/ram/total-memory-in-gb", queryItems: queryItems) { [weak self] (result: Result<TotalRamResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let allValues = response.data.result.flatMap { $0.values }
                    self?.maxRam = allValues.map { $0.value }.max()
                case .failure(let error):
                    self?.error = "Decode error: \(error.localizedDescription)"
                }
            }
        }
    }
}
