// ObServe/Modules/MetricsModel.swift
import Foundation
import Combine

class MetricsModel: ObservableObject {
    @Published var uptime: String = "00 : 00 : 00"
    @Published var memory: Double = 0
    @Published var cpu: Double = 0
    @Published var storage: Double = 0
    @Published var ping: Double = 0
    @Published var network: Double = 0

    private var uptimeSeconds: Int

    init() {
        uptimeSeconds = 0
        uptime = Self.formatUptime(uptimeSeconds)
        memory = Double.random(in: 20...96)
        cpu = Double.random(in: 0...100)
        storage = Double.random(in: 1...2)
        ping = Double.random(in: 10...100)
        network = Double.random(in: 10...100)
    }

    func updateMockValues() {
        memory = Self.clamp(memory + Double.random(in: -1...1), min: 20, max: 96)
        cpu = Self.clamp(cpu + Double.random(in: -5...5), min: 0, max: 100)
        storage = Self.clamp(storage + Double.random(in: -0.01...0.01), min: 1, max: 2)
        ping = Self.clamp(ping + Double.random(in: -2...2), min: 10, max: 100)
        network = Self.clamp(network + Double.random(in: -3...3), min: 10, max: 100)
        uptimeSeconds += 3
        uptime = Self.formatUptime(uptimeSeconds)
    }
    
    private static func clamp(_ value: Double, min: Double, max: Double) -> Double {
        return Swift.max(min, Swift.min(max, value))
    }
    
    func updateMockValuesRandom() {
        memory = Double.random(in: 20...96)
        cpu = Double.random(in: 0...100)
        storage = Double.random(in: 1...2)
        ping = Double.random(in: 10...100)
        network = Double.random(in: 10...100)
        uptimeSeconds += 3
        uptime = Self.formatUptime(uptimeSeconds)
    }

    private static func formatUptime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d : %02d : %02d", h, m, s)
    }
}
