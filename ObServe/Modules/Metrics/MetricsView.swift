//
//  MetricsView.swift
//  ObServe
//
//  Created by Daniel Schatz on 20.07.25.
//
import SwiftUI

struct MetricsView: View {
    @ObservedObject var model: MetricsModel
    @StateObject private var cpuFetcher: LiveMetricsFetcher
    @StateObject private var ramFetcher: LiveRamFetcher
    @StateObject private var pingFetcher: LivePingFetcher
    @StateObject private var storageFetcher: LiveStorageFetcher
    @StateObject private var diskTotalSizeFetcher: LiveDiskTotalSizeFetcher
    @StateObject private var uptimeFetcher: LiveUptimeFetcher
    @StateObject private var totalRamFetcher: LiveTotalRamFetcher
    @StateObject private var networkInFetcher: LiveNetworkInFetcher
    @StateObject private var networkOutFetcher: LiveNetworkOutFetcher

    init(model: MetricsModel, server: ServerModuleItem) {
        self.model = model
        _cpuFetcher = StateObject(wrappedValue: LiveMetricsFetcher(ip: server.ip, port: server.port))
        _ramFetcher = StateObject(wrappedValue: LiveRamFetcher(ip: server.ip, port: server.port))
        _pingFetcher = StateObject(wrappedValue: LivePingFetcher(ip: server.ip, port: server.port))
        _storageFetcher = StateObject(wrappedValue: LiveStorageFetcher(ip: server.ip, port: server.port))
        _diskTotalSizeFetcher = StateObject(wrappedValue: LiveDiskTotalSizeFetcher(ip: server.ip, port: server.port))
        _totalRamFetcher = StateObject(wrappedValue: LiveTotalRamFetcher(ip: server.ip, port: server.port))
        _uptimeFetcher = StateObject(wrappedValue: LiveUptimeFetcher(ip: server.ip, port: server.port))
        _networkInFetcher = StateObject(wrappedValue: LiveNetworkInFetcher(ip: server.ip, port: server.port))
        _networkOutFetcher = StateObject(wrappedValue: LiveNetworkOutFetcher(ip: server.ip, port: server.port))
    }
    
    var body: some View {
        let avgCPU = cpuFetcher.entries.isEmpty ? 0 : cpuFetcher.entries.map(\.value).reduce(0, +) / Double(cpuFetcher.entries.count)
        let avgRAM = ramFetcher.entries.isEmpty ? 0 : ramFetcher.entries.map(\.value).reduce(0, +) / Double(ramFetcher.entries.count)
        let maxRAM = totalRamFetcher.maxRam ?? 0 // Use total RAM if available
        let avgPing = pingFetcher.entries.isEmpty ? 0 : pingFetcher.entries.map(\.value).reduce(0, +) / Double(pingFetcher.entries.count)
        let avgStorage = storageFetcher.entries.isEmpty ? 0 : storageFetcher.entries.map(\.value).reduce(0, +) / Double(storageFetcher.entries.count)
        let maxStorage = diskTotalSizeFetcher.maxDiskSize ?? 0 // Use max disk size if available
        let avgNetworkIn = networkInFetcher.entries.isEmpty ? 0 : networkInFetcher.entries.map(\.value).reduce(0, +) / Double(networkInFetcher.entries.count)
        let avgNetworkOut = networkOutFetcher.entries.isEmpty ? 0 : networkOutFetcher.entries.map(\.value).reduce(0, +) / Double(networkOutFetcher.entries.count)

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                if let uptime = uptimeFetcher.uptime {
                    UpdateLabel(label: "UPTIME", value: uptime)
                } else {
                    UpdateLabel(label: "UPTIME", value: 0)
                }
                UpdateLabel(label: "MEMORY", value: avgRAM, max: maxRAM, unit: "GB", decimalPlaces: 2, showPercent: true)
            }
            HStack(spacing: 16) {
                UpdateLabel(label: "CPU USAGE", value: avgCPU * 100, unit: "%", decimalPlaces: 2, showPercent: true)
                UpdateLabel(label: "STORAGE", value: avgStorage, max: maxStorage, unit: "GB", decimalPlaces: 2, showPercent: true)
            }
            HStack(spacing: 16) {
                UpdateLabel(label: "PING", value: avgPing, unit: "MS", decimalPlaces: 0)
                HStack(spacing: 8) {
                    UpdateLabel(label: "IN", value: avgNetworkIn, unit: "kB/s", decimalPlaces: 0)
                    UpdateLabel(label: "OUT", value: avgNetworkOut, unit: "kB/s", decimalPlaces: 0)
                }
            }
        }
        .alert("CPU Fetch Error", isPresented: .constant(cpuFetcher.error != nil)) {
            Button("OK") { cpuFetcher.error = nil }
        } message: {
            Text(cpuFetcher.error ?? "Unknown error")
        }
        .alert("RAM Fetch Error", isPresented: .constant(ramFetcher.error != nil)) {
            Button("OK") { ramFetcher.error = nil }
        } message: {
            Text(ramFetcher.error ?? "Unknown error")
        }
        .alert("Ping Fetch Error", isPresented: .constant(pingFetcher.error != nil)) {
            Button("OK") { pingFetcher.error = nil }
        } message: {
            Text(pingFetcher.error ?? "Unknown error")
        }
        .alert("Storage Fetch Error", isPresented: .constant(storageFetcher.error != nil)) {
            Button("OK") { storageFetcher.error = nil }
        } message: {
            Text(storageFetcher.error ?? "Unknown error")
        }
        .alert("Disk Size Fetch Error", isPresented: .constant(diskTotalSizeFetcher.error != nil)) {
            Button("OK") { diskTotalSizeFetcher.error = nil }
        } message: {
            Text(diskTotalSizeFetcher.error ?? "Unknown error")
        }
        .alert("Total RAM Fetch Error", isPresented: .constant(totalRamFetcher.error != nil)) {
            Button("OK") { totalRamFetcher.error = nil }
        } message: {
            Text(totalRamFetcher.error ?? "Unknown error")
        }
        .alert("Network In Fetch Error", isPresented: .constant(networkInFetcher.error != nil)) {
            Button("OK") { networkInFetcher.error = nil }
        } message: {
            Text(networkInFetcher.error ?? "Unknown error")
        }
        .alert("Network Out Fetch Error", isPresented: .constant(networkOutFetcher.error != nil)) {
            Button("OK") { networkOutFetcher.error = nil }
        } message: {
            Text(networkOutFetcher.error ?? "Unknown error")
        }
        .alert("Uptime Fetch Error", isPresented: .constant(uptimeFetcher.error != nil)) {
            Button("OK") { uptimeFetcher.error = nil }
        } message: {
            Text(uptimeFetcher.error ?? "Unknown error")
        }
        .onAppear {
            cpuFetcher.start()
            ramFetcher.start()
            pingFetcher.start()
            storageFetcher.start()
            diskTotalSizeFetcher.fetch()
            totalRamFetcher.fetch()
            networkInFetcher.start()
            networkOutFetcher.start()
            uptimeFetcher.start()
        }
        .onDisappear {
            cpuFetcher.stop()
            ramFetcher.stop()
            pingFetcher.stop()
            storageFetcher.stop()
            networkInFetcher.stop()
            networkOutFetcher.stop()
            uptimeFetcher.stop()
        }
    }
}

struct MetricsView_Previews: PreviewProvider {
    static var previews: some View {
        let server = ServerModuleItem(name: "Test Server", ip: "100.103.85.36", port: "8080")
        MetricsView(model: MetricsModel(), server: server)
            .padding()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}
