//
//  NetworkMetricsView.swift
//  ObServe
//
//  Created by GitHub Copilot on 22.09.25.
//

import SwiftUI

struct NetworkMetricsView: View {
    @ObservedObject var metricsManager: MetricsManager

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 12)

                HStack(spacing: 16) {
                    UpdateLabel(
                        label: "IN",
                        value: metricsManager.avgNetworkIn,
                        unit: "kB/s",
                        decimalPlaces: 0
                    )
                    UpdateLabel(
                        label: "OUT",
                        value: metricsManager.avgNetworkOut,
                        unit: "kB/s",
                        decimalPlaces: 0
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if metricsManager.ping != nil || metricsManager.uploadSpeed != nil || metricsManager.downloadSpeed != nil {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 1)

                    HStack(spacing: 16) {
                        if let ping = metricsManager.ping {
                            UpdateLabel(
                                label: "PING",
                                value: ping,
                                unit: "ms",
                                decimalPlaces: 1
                            )
                        }
                        if let upload = metricsManager.uploadSpeed {
                            UpdateLabel(
                                label: "UPLOAD",
                                value: upload,
                                unit: "Mbps",
                                decimalPlaces: 1
                            )
                        }
                        if let download = metricsManager.downloadSpeed {
                            UpdateLabel(
                                label: "DOWNLOAD",
                                value: download,
                                unit: "Mbps",
                                decimalPlaces: 1
                            )
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
            )
            .overlay(alignment: .topLeading) {
                HStack {
                    Text("NETWORK")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(10)
                .background(Color.black)
                .padding(.top, -18)
                .padding(.leading, 10)
            }
        }
        .padding(.vertical, 20)
    }
}

#Preview {
    let sampleServer = ServerModuleItem(machineUUID: UUID(), name: "Test Server", type: "Server")
    let metricsManager = MetricsManager(server: sampleServer)

    NetworkMetricsView(metricsManager: metricsManager)
        .background(Color.black)
}
