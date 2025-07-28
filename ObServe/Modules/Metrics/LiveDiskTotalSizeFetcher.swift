import Foundation
import Combine

class LiveDiskTotalSizeFetcher: ObservableObject {
    @Published var maxDiskSize: Double? = nil
    @Published var error: String?
    private let networkService: NetworkService
    
    init(ip: String, port: String) {
        self.networkService = NetworkService(ip: ip, port: port)
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
        networkService.fetch(endpoint: "/metrics/disk/total-size-in-gb-all-volumes", queryItems: queryItems) { [weak self] (result: Result<TotalDiskResponse, Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let response):
                    let allValues = response.data.result.flatMap { $0.values }
                    self?.maxDiskSize = allValues.map { $0.value }.max()
                case .failure(let error):
                    self?.error = "Decode error: \(error.localizedDescription)"
                }
            }
        }
    }
}
