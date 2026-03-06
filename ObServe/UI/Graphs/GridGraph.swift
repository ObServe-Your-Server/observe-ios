import SwiftUI

struct TimeSeriesGridChart: View {
    let currentValue: Double
    let maximum: Double
    let serverId: UUID?
    let metricType: String?

    @State private var percentageHistory: [Double] = []
    
    // Grid configuration
    private let rows = 10
    private let columns = 30
    private let cellSize: CGFloat = 8.7
    private let maxHistoryCount = 30
    
    private var cellSpacing: CGFloat { cellSize * 0.2 }
    
    private var currentPercentage: Double {
        guard maximum > 0 else { return 0 }
        return min(max((currentValue / maximum) * 100, 0), 100)
    }
    
    // Colors
    private let gridColor = Color(red: 0x80/255, green: 0x80/255, blue: 0x80/255).opacity(0.2)
    private let fillColor = Color.white
    private let axisColor = Color(red: 0x80/255, green: 0x80/255, blue: 0x80/255)
    
    private func calculateActualSpacing(for cellSize: CGFloat) -> CGFloat { cellSize * 0.2 }
    private func calculateGridHeight(cellSize: CGFloat, spacing: CGFloat) -> CGFloat {
        CGFloat(rows) * cellSize + CGFloat(rows - 1) * spacing
    }
    
    var body: some View {
        let actualCellSize = cellSize
        let actualSpacing = cellSpacing
        let gridHeight = calculateGridHeight(cellSize: actualCellSize, spacing: actualSpacing)

        GridContentView(
            timeSeriesData: percentageHistory,
            currentPercentage: currentPercentage,
            actualCellSize: actualCellSize,
            actualSpacing: actualSpacing,
            gridHeight: gridHeight,
            rows: rows,
            columns: columns,
            gridColor: gridColor,
            fillColor: fillColor,
            axisColor: axisColor
        )
        .frame(maxWidth: .infinity)
        .onChange(of: currentValue) { _, _ in updatePercentageHistory() }
        .onChange(of: maximum) { _, _ in updatePercentageHistory() }
        .onAppear {
            loadCachedHistory()
            updatePercentageHistory()
        }
    }
    
    private func loadCachedHistory() {
        // Only load cached history if we have both serverId and metricType, and history is empty
        guard let serverId = serverId,
              let metricType = metricType,
              percentageHistory.isEmpty else {
            return
        }

        // Load cached metric data from SharedStorageManager
        if let cachedData = SharedStorageManager.shared.loadMetricData(serverId: serverId, metricType: metricType) {
            percentageHistory = cachedData.history
        }
    }

    private func updatePercentageHistory() {
        let newPercentage = currentPercentage
        percentageHistory.append(newPercentage)
        if percentageHistory.count > maxHistoryCount {
            percentageHistory.removeFirst(percentageHistory.count - maxHistoryCount)
        }
    }
}

struct GridContentView: View {
    let timeSeriesData: [Double]
    let currentPercentage: Double
    let actualCellSize: CGFloat
    let actualSpacing: CGFloat
    let gridHeight: CGFloat
    let rows: Int
    let columns: Int
    let gridColor: Color
    let fillColor: Color
    let axisColor: Color
    
    var body: some View {
        // Geometrie/Vorgaben wie bisher
        let gridWidth = CGFloat(columns) * actualCellSize + CGFloat(columns - 1) * actualSpacing
        let axisThickness: CGFloat = 1
        let axisGap: CGFloat = actualCellSize * 0.5
        let labelSpace: CGFloat = 24

        // Daten auf Spaltenbreite bringen
        let displayData: [Double] = {
            let dataCount = timeSeriesData.count
            if dataCount >= columns {
                return Array(timeSeriesData.suffix(columns))
            } else {
                let padding = Array(repeating: 0.0, count: columns - dataCount)
                return padding + timeSeriesData
            }
        }()
        
        // Canvas with labels and grid
        Canvas { context, size in
                    let sideMargin = labelSpace + axisGap * 2
                    let totalDrawnWidth = sideMargin * 2 + gridWidth
                    let originX = (size.width - totalDrawnWidth) / 2

                    let gridX = originX + sideMargin
                    let gridY = axisGap + labelSpace

                    let yAxisX = originX + sideMargin - axisGap
                    let xAxisY = gridY + gridHeight + axisGap
                    let rightAxisX = gridX + gridWidth + axisGap

                    // Render labels above the grid
                    // "LOAD %" label aligned with leftmost grid cell
                    let loadLabel = context.resolve(
                        Text("LOAD")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.6))
                    )
                    context.draw(loadLabel, at: CGPoint(x: gridX, y: gridY - 4), anchor: .bottomLeading)

                    // Percentage value aligned with rightmost grid cell
                    let percentageLabel = context.resolve(
                        Text(String(format: "%.1f", currentPercentage))
                            .font(.system(size: 16, weight: .regular))
                            .foregroundColor(.white)
                    )
                    context.draw(percentageLabel, at: CGPoint(x: rightAxisX, y: gridY - 4), anchor: .bottomTrailing)


                    // Y-Achse
                    context.fill(
                        Rectangle().path(in: CGRect(
                            x: yAxisX - axisThickness/2,
                            y: 10/9*labelSpace,
                            width: axisThickness,
                            height: xAxisY + 1/10 * axisGap - 1.11*labelSpace
                        )),
                        with: .color(axisColor)
                    )
                    
                    // X-Achse (from left axis to right axis)
                    context.fill(
                        Rectangle().path(in: CGRect(
                            x: yAxisX,
                            y: xAxisY - axisThickness/2,
                            width: rightAxisX - yAxisX,
                            height: axisThickness
                        )),
                        with: .color(axisColor)
                    )
                    
                    // Grid-Zellen
                    for row in 0..<rows {
                        for col in 0..<columns {
                            let x = gridX + CGFloat(col) * (actualCellSize + actualSpacing)
                            let y = gridY + CGFloat(rows - 1 - row) * (actualCellSize + actualSpacing)
                            let rect = CGRect(x: x, y: y, width: actualCellSize, height: actualCellSize)
                            
                            let usageValue = displayData[col]
                            let percentageLevel = Double(row) * 10.0
                            let cellColor = (usageValue > percentageLevel) ? fillColor : gridColor
                            
                            context.fill(Rectangle().path(in: rect), with: .color(cellColor))
                        }
                    }
                    
                    // Right Y-axis
                    context.fill(
                        Rectangle().path(in: CGRect(
                            x: rightAxisX - axisThickness/2,
                            y: 10/9*labelSpace,
                            width: axisThickness,
                            height: xAxisY + 1/10 * axisGap - 1.11*labelSpace
                        )),
                        with: .color(axisColor)
                    )

                    // Y-Tick: 50% only, pointing inward on both axes
                    let tick50Y: CGFloat = {
                        let row4Y = gridY + CGFloat(rows - 1 - 4) * (actualCellSize + actualSpacing)
                        let row5Y = gridY + CGFloat(rows - 1 - 5) * (actualCellSize + actualSpacing)
                        return (row4Y + actualCellSize + row5Y) / 2
                    }()
                    let tickThickness = axisThickness
                    let tickLength: CGFloat = 5
                    // Left tick: points right into graph
                    context.fill(
                        Rectangle().path(in: CGRect(
                            x: yAxisX,
                            y: tick50Y - tickThickness/2,
                            width: tickLength,
                            height: tickThickness
                        )),
                        with: .color(axisColor)
                    )
                    // Right tick: points left into graph
                    context.fill(
                        Rectangle().path(in: CGRect(
                            x: rightAxisX - tickLength,
                            y: tick50Y - tickThickness/2,
                            width: tickLength,
                            height: tickThickness
                        )),
                        with: .color(axisColor)
                    )

                    // X-Ticks: pointing inward (upward)
                    let tickColumns = [4, 9, 14, 19, 24]
                    for colIndex in tickColumns {
                        let tickX = gridX + CGFloat(colIndex + 1) * (actualCellSize + actualSpacing) - actualSpacing/2
                        context.fill(
                            Rectangle().path(in: CGRect(x: tickX - axisThickness/2, y: xAxisY - 3, width: axisThickness, height: 3)),
                            with: .color(axisColor)
                        )
                    }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: axisGap + labelSpace + gridHeight + axisGap * 2,
            maxHeight: axisGap + labelSpace + gridHeight + axisGap * 2
        )
    }
}




















// Optional: Demo/Preview bleibt unverändert
struct PercentageLabel: View {
    let currentPercentage: Double
    var body: some View {
        HStack {
            Spacer()
            Text("\(currentPercentage, specifier: "%.1f")%")
                .font(.system(size: 32, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            Text("NOW")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .padding(.leading, 8)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
}

struct ContentView: View {
    @State private var currentValue: Double = 50.0
    @State private var maximum: Double = 100.0
    
    var body: some View {
        VStack {
            TimeSeriesGridChart(currentValue: currentValue, maximum: maximum, serverId: nil, metricType: nil)
                .preferredColorScheme(.dark)
            // … Demo-Controls wie gehabt …
        }
        .background(Color.black)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    currentValue = Double.random(in: 10...maximum)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
