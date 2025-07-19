//
//  MetricsView.swift
//  ObServe
//
//  Created by Daniel Schatz on 20.07.25.
//
import SwiftUI

// Dummy MetricsView for demonstration
struct MetricsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {
                DateLabel(label: "UPTIME", date: "20 : 56 : 12")
                UpdateLabel(label: "MEMORY", value: 25.4, max: 96.00, unit: "GB", showPercent: true)
            }
            HStack(spacing: 16) {
                UpdateLabel(label: "CPU USAGE", value: 70, unit: "%", showPercent: true)
                UpdateLabel(label: "STORAGE", value: 1.26, max: 2, unit: "TB", showPercent: true)
            }
            HStack(spacing: 16) {
                UpdateLabel(label: "PING", value: 20, unit: "ms")
                UpdateLabel(label: "NETWORK TRAFFIC", value: 32, unit: "kB/s")
            }
        }
    }
}
