//
//  MetricsView.swift
//  ObServe
//
//  Created by Daniel Schatz on 20.07.25.
//
import SwiftUI

struct MetricsViewSimplified: View {
    @ObservedObject var metricsManager: MetricsManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 18) {
                UpdateLabel(label: "UPTIME", value: metricsManager.uptime)
                UpdateLabel(
                    label: "MEMORY",
                    value: metricsManager.avgRAM,
                    max: metricsManager.maxRAM,
                    unit: "GB",
                    decimalPlaces: 2,
                    showPercent: true
                )
            }
            
            HStack(spacing: 18) {
                UpdateLabel(
                    label: "CPU USAGE",
                    value: metricsManager.avgCPU * 100,
                    unit: "%",
                    decimalPlaces: 2,
                    showPercent: false
                )
                UpdateLabel(
                    label: "STORAGE",
                    value: metricsManager.avgStorage,
                    max: metricsManager.maxStorage,
                    unit: "GB",
                    decimalPlaces: 2,
                    showPercent: true
                )
            }
            
            HStack(spacing: 18) {
                UpdateLabel(label: "IN", value: metricsManager.avgNetworkIn, formattedText: formatBytes(metricsManager.avgNetworkIn))
                UpdateLabel(label: "OUT", value: metricsManager.avgNetworkOut, formattedText: formatBytes(metricsManager.avgNetworkOut))
            }
        }
        .alert("Metrics Error", isPresented: .constant(metricsManager.error != nil)) {
            Button("OK") { metricsManager.error = nil }
        } message: {
            Text(metricsManager.error ?? "Unknown error")
        }
    }
}
