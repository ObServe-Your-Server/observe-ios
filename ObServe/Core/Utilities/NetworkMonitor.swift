//
//  NetworkMonitor.swift
//  ObServe
//

import Foundation
import Network
import Combine

@MainActor
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()

    @Published private(set) var isConnected: Bool = true
    @Published private(set) var showReconnectedBanner: Bool = false

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.observe.networkmonitor", qos: .utility)
    private var isCurrentlyDisconnected = false
    private var reconnectTask: Task<Void, Never>?

    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let connected = path.status == .satisfied

                if !connected {
                    guard !self.isCurrentlyDisconnected else { return }
                    self.isCurrentlyDisconnected = true
                    self.isConnected = false
                    self.showReconnectedBanner = false
                    self.reconnectTask?.cancel()
                } else {
                    guard !self.isConnected else { return }
                    self.isCurrentlyDisconnected = false
                    self.isConnected = true
                    self.reconnectTask?.cancel()
                    self.reconnectTask = Task { @MainActor in
                        self.showReconnectedBanner = true
                        try? await Task.sleep(nanoseconds: 3_000_000_000)
                        guard !Task.isCancelled else { return }
                        self.showReconnectedBanner = false
                    }
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
        reconnectTask?.cancel()
    }
}
