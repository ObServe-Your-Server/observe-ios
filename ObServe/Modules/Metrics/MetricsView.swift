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

    init(model: MetricsModel, server: ServerModuleItem) {
        self.model = model
        _cpuFetcher = StateObject(wrappedValue: LiveMetricsFetcher(ip: server.ip, port: server.port))
    }
    
    var body: some View {
        let avgCPU = cpuFetcher.entries.isEmpty ? 0 : cpuFetcher.entries.map(\.value).reduce(0, +) / Double(cpuFetcher.entries.count)

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                DateLabel(label: "UPTIME", date: model.uptime)
                UpdateLabel(label: "MEMORY", value: model.memory, max: model.maxMemory, unit: "GB", decimalPlaces: 2, showPercent: true)
            }
            HStack(spacing: 16) {
                UpdateLabel(label: "CPU USAGE", value: avgCPU * 100, unit: "%", decimalPlaces: 2, showPercent: true)
                UpdateLabel(label: "STORAGE", value: model.storage, max: model.maxStorage, unit: "TB", decimalPlaces: 2, showPercent: true, )
            }
            HStack(spacing: 16) {
                UpdateLabel(label: "PING", value: model.ping, unit: "ms", decimalPlaces: 0)
                UpdateLabel(label: "NETWORK TRAFFIC", value: model.network, unit: "kB/s", decimalPlaces: 0)
            }
        }
        .alert("CPU Fetch Error", isPresented: .constant(cpuFetcher.error != nil)) {
                    Button("OK") {
                        cpuFetcher.error = nil
                    }
                } message: {
                    Text(cpuFetcher.error ?? "Unknown error")
        }
        .onAppear { cpuFetcher.start() }
        .onDisappear { cpuFetcher.stop() }
    }
}

struct MetricsView_Previews: PreviewProvider {
    static var previews: some View {
        let server = ServerModuleItem(name: "Test Server", ip: "127.0.0.1", port: "8080")
        MetricsView(model: MetricsModel(), server: server)
            .padding()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}
