//
//  MetricDisplayComponents.swift
//  observeMetricsWidget
//
//  Created by Daniel Schatz on 24.10.25.
//

import SwiftUI

// MARK: - Formatting Functions (matching main app)

/// Format uptime in seconds to "HH : MM : SS" format (with spaces around colons)
/// Matches formatDuration() from UpdateLabel.swift
func formatUptime(_ uptime: TimeInterval?) -> String {
    guard let uptime = uptime, uptime > 0 else {
        return "---"
    }

    let totalSeconds = Int(uptime)
    let hours = totalSeconds / 3600
    let minutes = (totalSeconds % 3600) / 60
    let secs = totalSeconds % 60

    return String(format: "%d : %02d : %02d", hours, minutes, secs)
}

/// Format value with decimal places (matching formatValue() from UpdateLabel.swift)
func formatValue(_ value: Double, decimalPlaces: Int = 2) -> String {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = decimalPlaces
    formatter.numberStyle = .decimal
    return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
}

// MARK: - Progress Bar (matching PercentLabel.swift)

/// Progress bar matching the exact styling from PercentLabel.swift
struct WidgetPercentLabel: View {
    var value: Double
    var maximum: Double = 100.0
    
    var body: some View {
            let percent = (maximum == 0) ? 0 : min(max(value / maximum, 0), 1)
            
            // Debug: Print the values being used
            let _ = print("WidgetPercentLabel DEBUG: value=\(value), maximum=\(maximum), calculated percent=\(percent)")
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.4))
                    Rectangle()
                        .frame(width: geometry.size.width * percent, height: 6)
                        .foregroundColor(Color("ObServeGray"))
                    Rectangle()
                        .frame(width: 1, height: 6)
                        .foregroundColor(Color.gray.opacity(0.4))
                        .position(x: geometry.size.width, y: geometry.size.height / 2)
                }
            }
            .frame(height: 8)
            .padding(.horizontal, 4)
        }
}

// MARK: - Update Label Style Component

/// Metric display matching UpdateLabel.swift from main app
struct WidgetUpdateLabel: View {
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
                    .font(.custom("IBM Plex Sans", size: 12))
                    .fontWeight(.medium)
                
                Text("\(formatValue(value, decimalPlaces: decimalPlaces))\((max == 0) ? "" : " / \(formatValue(max))")\(unit.isEmpty ? "" : " \(unit)")")
                    .foregroundColor(.white)
                    .font(.custom("IBM Plex Sans", size: 16))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .contentTransition(.numericText(countsDown: value < oldValue))
                    .animation(.easeInOut, value: value)
                
                if showPercent {
                    WidgetPercentLabel(value: value, maximum: (max == 0) ? 100 : max)
                        .animation(.easeInOut, value: value)
                }
            }
            Spacer()
        }
        .onAppear {
            oldValue = value
        }
        .onChange(of: value) { oldValue, newValue in
            self.oldValue = newValue
        }
    }
}

// MARK: - Network Metric Display (simplified UpdateLabel style)

/// Network metric display matching UpdateLabel styling
struct WidgetNetworkLabel: View {
    var label: String
    var value: Double?
    var decimalPlaces: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Label
            Text(label)
                .foregroundColor(Color.gray)
                .font(.custom("IBM Plex Sans", size: 12))
                .fontWeight(.medium)

            // Value
            Text(valueString)
                .foregroundColor(.white)
                .font(.custom("IBM Plex Sans", size: 16))
                .lineLimit(1)
        }
    }

    private var valueString: String {
        guard let value = value else {
            return "---"
        }

        // Force rounding to match main app exactly (round first, then format)
        let roundedValue = round(value)
        return "\(formatValue(roundedValue, decimalPlaces: decimalPlaces)) kB/s"
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        WidgetUpdateLabel(
            label: "MEMORY",
            value: 23.4,
            max: 96.00,
            unit: "GB",
            decimalPlaces: 2,
            showPercent: true
        )

        WidgetUpdateLabel(
            label: "CPU USAGE",
            value: 45.0,
            max: 0,
            unit: "%",
            decimalPlaces: 0,
            showPercent: false
        )

        WidgetNetworkLabel(
            label: "IN",
            value: 775168,
            decimalPlaces: 0
        )
    }
    .padding()
    .background(Color.black)
}
