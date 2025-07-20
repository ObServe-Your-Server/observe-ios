//
//  MetricsService.swift
//  ObServe
//
//  Created by Daniel Schatz on 21.07.25.
//

// ObServe/Modules/MetricsService.swift
import Foundation
import Combine

class MetricsService: ObservableObject {
    static let shared = MetricsService()
    @Published var metrics: [UUID: MetricsModel] = [:]
    private var timer: AnyCancellable?

    private init() {
        timer = Timer.publish(every: 3, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateAllMetrics()
            }
    }

    func registerServer(id: UUID) -> MetricsModel {
        if let model = metrics[id] { return model }
        let model = MetricsModel()
        metrics[id] = model
        return model
    }

    private func updateAllMetrics() {
        for model in metrics.values {
            model.updateMockValues()
        }
    }
}
