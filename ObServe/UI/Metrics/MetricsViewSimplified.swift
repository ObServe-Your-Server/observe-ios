//
//  MetricsView.swift
//  ObServe
//
//  Created by Daniel Schatz on 20.07.25.
//
import SwiftUI

struct MetricsViewSimplified: View {
    @ObservedObject var metricsManager: MetricsManager

    private var storageUnit: String {
        metricsManager.maxStorage >= 1000 ? "TB" : "GB"
    }

    private var storageValue: Double {
        metricsManager.maxStorage >= 1000 ? metricsManager.avgStorage / 1000 : metricsManager.avgStorage
    }

    private var storageMax: Double {
        metricsManager.maxStorage >= 1000 ? metricsManager.maxStorage / 1000 : metricsManager.maxStorage
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 24) {
                UpdateLabel(label: "UPTIME", value: metricsManager.uptime)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("STATUS")
                            .foregroundColor(Color.gray)
                            .font(.plexSans(size: 12, weight: .medium))
                        Text(metricsManager.machineStatus.rawValue)
                            .foregroundColor(.white)
                            .animation(.easeInOut, value: metricsManager.machineStatus.rawValue)
                    }
                    Spacer()
                }
            }

            HStack(spacing: 24) {
                UpdateLabel(
                    label: "CPU",
                    value: metricsManager.avgCPU * 100,
                    unit: "%",
                    decimalPlaces: 2,
                    showPercent: true
                )
                UpdateLabel(
                    label: "MEMORY",
                    value: metricsManager.avgRAM,
                    max: metricsManager.maxRAM,
                    unit: "GB",
                    decimalPlaces: 2,
                    showPercent: true
                )
            }

            HStack(spacing: 24) {
                UpdateLabel(
                    label: "IN",
                    value: metricsManager.avgNetworkIn,
                    formattedText: formatBytes(metricsManager.avgNetworkIn)
                )
                UpdateLabel(
                    label: "OUT",
                    value: metricsManager.avgNetworkOut,
                    formattedText: formatBytes(metricsManager.avgNetworkOut)
                )
            }
        }
    }
}
