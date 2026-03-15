//
//  UpdateLabel.swift
//  ObServe
//
//  Created by Daniel Schatz on 20.07.25.
//
import SwiftUI

func formatBytes(_ bytes: Double) -> String {
    let kb = bytes / 1024.0
    if kb >= 1024.0 {
        return String(format: "%.2f MB/s", kb / 1024.0)
    } else {
        return String(format: "%.0f kB/s", kb)
    }
}

func formatValue(_ value: Double, decimalPlaces: Int = 2, forceDecimals: Bool = false) -> String {
    if forceDecimals {
        return String(format: "%.\(decimalPlaces)f", value)
    }
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0

    // If precise data is enabled, use the specified decimal places
    // Otherwise, round to whole numbers (0 decimal places) for cleaner display
    if SettingsManager.shared.preciseDataEnabled {
        formatter.maximumFractionDigits = decimalPlaces
    } else {
        formatter.maximumFractionDigits = 0
    }

    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
}

func formatDuration(_ seconds: Double, showDays: Bool = true) -> String {
    let totalSeconds = Int(seconds)
    if showDays {
        let days = totalSeconds / 86400
        let hours = (totalSeconds % 86400) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        return String(format: "%02d : %02d : %02d : %02d", days, hours, minutes, secs)
    } else {
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        return String(format: "%02d : %02d : %02d", hours, minutes, secs)
    }
}

struct UpdateLabel: View {
    var label: String
    var value: Double = 0.0
    var max: Double = 0.0
    var unit: String = ""
    var decimalPlaces: Int = 2
    var showPercent: Bool = false
    var showDaysInUptime: Bool = true
    var formattedText: String?
    var forceDecimals: Bool = false

    @State private var oldValue: Double = 0.0

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .foregroundColor(Color.gray)
                    .font(.plexSans(size: 12, weight: .medium))
                if label.uppercased() == "UPTIME" {
                    Text(formatDuration(value, showDays: showDaysInUptime))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .contentTransition(.numericText(countsDown: value < oldValue))
                        .animation(.easeInOut, value: value)
                } else if let text = formattedText {
                    Text(text)
                        .foregroundColor(.white)
                        .contentTransition(.numericText(countsDown: value < oldValue))
                        .animation(.easeInOut, value: value)
                } else {
                    Text(
                        "\(formatValue(value, decimalPlaces: decimalPlaces, forceDecimals: forceDecimals))\((max == 0) ? "" : " / \(formatValue(max, decimalPlaces: decimalPlaces, forceDecimals: forceDecimals))")\(unit.isEmpty ? "" : " \(unit)")"
                    )
                    .foregroundColor(.white)
                    .contentTransition(.numericText(countsDown: value < oldValue))
                    .animation(.easeInOut, value: value)
                }
                if showPercent {
                    PercentLabel(value: value, maximum: (max == 0) ? 100 : max)
                        .animation(.easeInOut, value: value)
                }
            }
            Spacer()
        }
        .onAppear {
            oldValue = value
        }
        .onChange(of: value) {
            oldValue = value
        }
    }
}
