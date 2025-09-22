//
//  ExpandableMetricBox.swift
//  ObServe
//
//  Created by GitHub Copilot on 22.09.25.
//

import SwiftUI

struct ExpandableMetricBox: View {
    let title: String
    let currentValue: Double
    let maximum: Double
    let unit: String?
    let decimalPlaces: Int
    let showPercent: Bool
    @State private var isExpanded: Bool = false
    
    init(title: String, currentValue: Double, maximum: Double, unit: String? = nil, decimalPlaces: Int = 1, showPercent: Bool = false) {
        self.title = title
        self.currentValue = currentValue
        self.maximum = maximum
        self.unit = unit
        self.decimalPlaces = decimalPlaces
        self.showPercent = showPercent
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Always create the chart to keep collecting data
            if isExpanded {
                TimeSeriesGridChart(
                    currentValue: currentValue,
                    maximum: maximum
                )
                .frame(height: 200)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .padding(.top, 30)
                .clipped()
            }

            // Content area
            if !isExpanded {
                VStack(spacing: 0) {
                    Spacer().frame(height: 20)

                    // Show metric info similar to UpdateLabel when collapsed
                    HStack {
                        PercentLabel(value: currentValue, maximum: maximum)
                            .frame(height: 8)

                        Spacer()
                            .frame(width: 20)

                        HStack(spacing: 4) {
                            if showPercent && maximum > 0 {
                                Text("\(String(format: "%.\(decimalPlaces)f", currentValue))/\(String(format: "%.\(decimalPlaces)f", maximum))")
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium))
                                if let unit = unit {
                                    Text(unit)
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .medium))
                                }
                                Text("(\(String(format: "%.1f", (currentValue / maximum) * 100))%)")
                                    .foregroundColor(Color.gray)
                                    .font(.system(size: 14))
                            } else {
                                Text(String(format: "%.\(decimalPlaces)f", currentValue))
                                    .foregroundColor(.white)
                                    .font(.system(size: 16, weight: .medium))
                                if let unit = unit {
                                    Text(unit)
                                        .foregroundColor(.white)
                                        .font(.system(size: 16, weight: .medium))
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
        )
        .overlay(alignment: .topLeading) {
            HStack {
                Text(title.uppercased())
                    .foregroundColor(.white)
                    .font(.system(size: 14, weight: .medium))

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .medium))
                }
            }
            .padding(10)
            .background(Color.black)
            .padding(.top, -18)
            .padding(.leading, 10)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ExpandableMetricBox(
            title: "CPU",
            currentValue: 45.3,
            maximum: 100.0
        )
        
        ExpandableMetricBox(
            title: "RAM",
            currentValue: 25.4,
            maximum: 100.0
        )
    }
    .padding()
    .background(Color.black)
}
