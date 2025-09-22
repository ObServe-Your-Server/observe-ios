//
//  UpdateLabel.swift
//  ObServe
//
//  Created by Daniel Schatz on 20.07.25.
//
import SwiftUI

func formatValue(_ value: Double, decimalPlaces: Int = 2) -> String {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = decimalPlaces
    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
}

func formatDuration(_ seconds: Double) -> String {
    let totalSeconds = Int(seconds)
    let days = totalSeconds / 86400
    let hours = (totalSeconds % 86400) / 3600
    let minutes = (totalSeconds % 3600) / 60
    let secs = totalSeconds % 60
    return String(format: "%02d : %02d : %02d : %02d", days, hours, minutes, secs)
}

struct UpdateLabel: View {
    var label: String
    var value: Double = 0.0
    var max: Double = 0.0
    var unit: String = ""
    var decimalPlaces: Int = 2
    var showPercent: Bool = false

    @State private var oldValue: Double = 0.0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .foregroundColor(Color.gray)
                    .font(.system(size: 12, weight: .medium))
                if label.uppercased() == "UPTIME" {
                    Text(formatDuration(value))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.8)
                        .contentTransition(.numericText(countsDown: value < oldValue))
                        .animation(.easeInOut, value: value)
                } else {
                    Text("\(formatValue(value, decimalPlaces: decimalPlaces))\((max == 0) ? "" : " / \(formatValue(max))")\(unit.isEmpty ? "" : " \(unit)")")
                        .foregroundColor(.white)
                        .contentTransition(.numericText(countsDown: value < oldValue))
                        .animation(.easeInOut, value: value)
                }
                if showPercent {
                    PercentLabel(value: value, maximum: (max==0) ? 100 : max)
                        .animation(.easeInOut, value: value)
                }
            }
            Spacer()
        }
        .onAppear {
            oldValue = value
        }
        .onChange(of: value) { newValue in
            oldValue = newValue
        }
    }
}
