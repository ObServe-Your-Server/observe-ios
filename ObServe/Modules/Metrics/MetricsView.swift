//
//  MetricsView.swift
//  ObServe
//
//  Created by Daniel Schatz on 20.07.25.
//
import SwiftUI

struct MetricsView: View {
    @ObservedObject var model: MetricsModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                DateLabel(label: "UPTIME", date: model.uptime)
                UpdateLabel(label: "MEMORY", value: model.memory, max: model.maxMemory, unit: "GB", decimalPlaces: 2, showPercent: true)
            }
            HStack(spacing: 16) {
                UpdateLabel(label: "CPU USAGE", value: model.cpu, unit: "%", decimalPlaces: 0, showPercent: true)
                UpdateLabel(label: "STORAGE", value: model.storage, max: model.maxStorage, unit: "TB", decimalPlaces: 2, showPercent: true, )
            }
            HStack(spacing: 16) {
                UpdateLabel(label: "PING", value: model.ping, unit: "ms", decimalPlaces: 0)
                UpdateLabel(label: "NETWORK TRAFFIC", value: model.network, unit: "kB/s", decimalPlaces: 0)
            }
        }
    }
}

struct MetricsView_Previews: PreviewProvider {
    static var previews: some View {
        MetricsView(model: MetricsModel())
            .padding()
            .background(Color.black)
            .previewLayout(.sizeThatFits)
    }
}
