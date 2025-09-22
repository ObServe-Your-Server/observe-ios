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
                
                // Network metrics content
                HStack(spacing: 40) {
                    // UPLINK
                    UpdateLabel(
                        label: "UPLINK",
                        value: metricsManager.avgNetworkOut / 1000,
                        unit: "MB/s",
                        decimalPlaces: 0
                    )
                    
                    // DOWNLINK
                    UpdateLabel(
                        label: "DOWNLINK",
                        value: metricsManager.avgNetworkIn / 1000,
                        unit: "MB/s",
                        decimalPlaces: 0
                    )
                    
                    // PING
                    UpdateLabel(
                        label: "PING",
                        value: metricsManager.avgPing,
                        unit: "ms",
                        decimalPlaces: 0
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
    let sampleServer = ServerModuleItem(name: "Test Server", ip: "192.168.1.100", port: "8080", type: "Server")
    let metricsManager = MetricsManager(server: sampleServer)
    
    NetworkMetricsView(metricsManager: metricsManager)
        .background(Color.black)
}
