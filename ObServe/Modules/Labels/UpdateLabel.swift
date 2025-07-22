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
                
                Text("\(formatValue(value, decimalPlaces: decimalPlaces))\((max == 0) ? "" : " / \(formatValue(max))")\(unit.isEmpty ? "" : " \(unit)")")
                        .foregroundColor(.white)
                        .contentTransition(.numericText(countsDown: value < oldValue))
                        .animation(.easeInOut, value: value)
                
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
