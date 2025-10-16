//
//  WidgetGridGraph.swift
//  observeMetricsWidget
//
//  Created by Daniel Schatz on 16.10.25.
//

import SwiftUI

struct WidgetGridGraph: View {
    let value: Double
    let maxValue: Double
    
    // Internal state to manage the rolling array of percentages
    @State private var percentageHistory: [Double] = []
    
    // Grid configuration - adapted for widget
    private let rows = 10
    private let columns = 12
    private let cellSize: CGFloat = 8
    private let maxHistoryCount = 12
    
    private var cellSpacing: CGFloat {
        cellSize * 0.15 // Slightly tighter spacing for widget
    }
    
    // Calculate current percentage
    private var currentPercentage: Double {
        guard maxValue > 0 else { return 0 }
        return min(max((value / maxValue) * 100, 0), 100)
    }
    
    // Colors
    private let gridColor = Color(red: 0x80/255, green: 0x80/255, blue: 0x80/255).opacity(0.2)
    private let fillColor = Color.white
    
    var body: some View {
        GeometryReader { geometry in
            WidgetGridContentView(
                timeSeriesData: percentageHistory,
                currentPercentage: currentPercentage,
                cellSize: cellSize,
                cellSpacing: cellSpacing,
                rows: rows,
                columns: columns,
                gridColor: gridColor,
                fillColor: fillColor
            )
        }
        .onChange(of: value) { oldValue, newValue in
            updatePercentageHistory()
        }
        .onChange(of: maxValue) { oldValue, newValue in
            updatePercentageHistory()
        }
        .onAppear {
            // Initialize with current percentage
            updatePercentageHistory()
        }
    }
    
    private func updatePercentageHistory() {
        let newPercentage = currentPercentage
        
        // Add the new percentage to the history
        percentageHistory.append(newPercentage)
        
        // Keep only the last 12 values (for 12 columns)
        if percentageHistory.count > maxHistoryCount {
            percentageHistory.removeFirst(percentageHistory.count - maxHistoryCount)
        }
    }
}

struct WidgetGridContentView: View {
    let timeSeriesData: [Double]
    let currentPercentage: Double
    let cellSize: CGFloat
    let cellSpacing: CGFloat
    let rows: Int
    let columns: Int
    let gridColor: Color
    let fillColor: Color
    
    var body: some View {
        let displayData: [Double] = {
            let dataCount = timeSeriesData.count
            if dataCount >= columns {
                return Array(timeSeriesData.suffix(columns))
            } else {
                let paddingCount = columns - dataCount
                let padding = Array(repeating: 0.0, count: paddingCount)
                return padding + timeSeriesData
            }
        }()
        
        Canvas { context, size in
            // Center the grid in the available space
            let gridWidth = CGFloat(columns) * cellSize + CGFloat(columns - 1) * cellSpacing
            let gridHeight = CGFloat(rows) * cellSize + CGFloat(rows - 1) * cellSpacing
            
            let startX = (size.width - gridWidth) / 2
            let startY = (size.height - gridHeight) / 2
            
            // Draw grid cells using the same logic as the main app
            for row in 0..<rows {
                for col in 0..<columns {
                    let x = startX + CGFloat(col) * (cellSize + cellSpacing)
                    let y = startY + CGFloat(rows - 1 - row) * (cellSize + cellSpacing)
                    
                    let rect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                    
                    var cellColor = gridColor
                    let usageValue = displayData[col]
                    let percentageLevel = Double(row) * 10.0
                    
                    // Fill cell if usage value exceeds the percentage level for this row
                    if usageValue > percentageLevel {
                        cellColor = fillColor
                    }
                    
                    context.fill(
                        Rectangle().path(in: rect),
                        with: .color(cellColor)
                    )
                }
            }
        }
    }
}

#Preview {
    WidgetGridGraph(value: 75, maxValue: 100)
        .background(Color.black)
        .padding()
}
