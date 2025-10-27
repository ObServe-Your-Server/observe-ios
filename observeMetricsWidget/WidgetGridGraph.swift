//
//  WidgetGridGraph.swift
//  observeMetricsWidget
//
//  Created by Daniel Schatz on 16.10.25.
//

import SwiftUI

struct WidgetGridGraph: View {
    let value: Double?
    let maxValue: Double
    let columns: Int
    let history: [Double] // Historical percentage values passed from cache

    private let rows = 10
    private let cellSize: CGFloat = 8

    private var cellSpacing: CGFloat {
        cellSize * 0.15
    }

    // Calculate current percentage
    private var currentPercentage: Double {
        guard let value = value, maxValue > 0 else { return 0 }
        return min(max((value / maxValue) * 100, 0), 100)
    }

    private var isOffline: Bool {
        return value == nil
    }

    // Colors
    private let gridColor = Color(red: 0x80/255, green: 0x80/255, blue: 0x80/255).opacity(0.2)
    private let fillColor = Color.white

    var body: some View {
        GeometryReader { geometry in
            WidgetGridContentView(
                timeSeriesData: isOffline ? [] : history,
                currentPercentage: currentPercentage,
                cellSize: cellSize,
                cellSpacing: cellSpacing,
                rows: rows,
                columns: columns,
                gridColor: gridColor,
                fillColor: fillColor,
                isOffline: isOffline
            )
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
    let isOffline: Bool

    var body: some View {
        let displayData: [Double] = {
            // If offline, show all zeros (empty grid)
            if isOffline {
                return Array(repeating: 0.0, count: columns)
            }

            // Create display data including current value
            var data = timeSeriesData
            
            // Add current percentage as the latest value
            data.append(currentPercentage)
            
            let dataCount = data.count
            if dataCount >= columns {
                return Array(data.suffix(columns))
            } else {
                let paddingCount = columns - dataCount
                let padding = Array(repeating: 0.0, count: paddingCount)
                return padding + data
            }
        }()

        Canvas { context, size in
            // Calculate grid dimensions
            let gridWidth = CGFloat(columns) * cellSize + CGFloat(columns - 1) * cellSpacing
            let gridHeight = CGFloat(rows) * cellSize + CGFloat(rows - 1) * cellSpacing

            // Center the grid horizontally and vertically
            let startX = (size.width - gridWidth) / 2
            let startY = (size.height - gridHeight) / 2

            // Draw grid cells - same logic as main app's GridGraph
            for row in 0..<rows {
                for col in 0..<columns {
                    let x = startX + CGFloat(col) * (cellSize + cellSpacing)
                    let y = startY + CGFloat(rows - 1 - row) * (cellSize + cellSpacing)

                    let rect = CGRect(x: x, y: y, width: cellSize, height: cellSize)

                    var cellColor = gridColor

                    // If offline, keep all cells at grid color (empty)
                    if !isOffline {
                        let usageValue = displayData[col]
                        let percentageLevel = Double(row) * 10.0  // Match main app: row 0 = 0%, row 1 = 10%, etc.

                        // Fill cell if usage value exceeds the percentage level for this row
                        if usageValue > percentageLevel {
                            cellColor = fillColor
                        }
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
    WidgetGridGraph(value: 75, maxValue: 100, columns: 14, history: [45, 50, 55, 60, 65, 70, 75])
        .background(Color.black)
        .padding()
}
