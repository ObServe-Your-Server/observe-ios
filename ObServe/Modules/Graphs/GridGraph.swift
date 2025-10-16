import SwiftUI

struct TimeSeriesGridChart: View {
    let currentValue: Double
    let maximum: Double
    
    @State private var percentageHistory: [Double] = []
    
    // Grid configuration
    private let rows = 10
    private let columns = 30
    private let cellSize: CGFloat = 7
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
    
    private func calculateActualCellSize(for width: CGFloat) -> CGFloat {
        let availableWidth = width * 0.55
        let totalSpacingWidth = CGFloat(columns - 1) * (cellSize * 0.2)
        let calculatedCellSize = (availableWidth - totalSpacingWidth) / CGFloat(columns)
        return min(max(cellSize, calculatedCellSize), cellSize * 1.2)
    }
    private func calculateActualSpacing(for cellSize: CGFloat) -> CGFloat { cellSize * 0.2 }
    private func calculateGridHeight(cellSize: CGFloat, spacing: CGFloat) -> CGFloat {
        CGFloat(rows) * cellSize + CGFloat(rows - 1) * spacing
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    let actualCellSize = calculateActualCellSize(for: geometry.size.width)
                    let actualSpacing = calculateActualSpacing(for: actualCellSize)
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
                        axisColor: axisColor,
                        screenWidth: geometry.size.width
                    )
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                }
            }
        }
        .onChange(of: currentValue) { _, _ in updatePercentageHistory() }
        .onChange(of: maximum) { _, _ in updatePercentageHistory() }
        .onAppear { updatePercentageHistory() }
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
    let screenWidth: CGFloat
    
    var body: some View {
        // Geometrie/Vorgaben wie bisher
        let gridWidth = CGFloat(columns) * actualCellSize + CGFloat(columns - 1) * actualSpacing
        let axisThickness: CGFloat = 1
        let axisGap: CGFloat = actualCellSize * 0.5
        
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
        
        // Überschrift/Labels (statisch) + Canvas darunter
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("LOAD %")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                
                Text("\(currentPercentage, specifier: "%.1f")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
            }
            // gleiche Breite wie der Canvas darunter
            .frame(width: gridWidth + axisGap * 4 + 120)
            
            HStack(spacing: 0) {
                Spacer()
                Canvas { context, _ in
                    let labelSpace: CGFloat = 30
                    let gridX = axisGap + axisGap + labelSpace
                    let gridY = axisGap + labelSpace
                    
                    let yAxisX = axisGap + labelSpace
                    let xAxisY = gridY + gridHeight + axisGap
                    
                    // Y-Achse
                    context.fill(
                        Rectangle().path(in: CGRect(
                            x: yAxisX - axisThickness/2,
                            y: labelSpace,
                            width: axisThickness,
                            height: xAxisY + 1/10 * axisGap - labelSpace
                        )),
                        with: .color(axisColor)
                    )
                    
                    // X-Achse
                    context.fill(
                        Rectangle().path(in: CGRect(
                            x: yAxisX,
                            y: xAxisY - axisThickness/2,
                            width: gridWidth + axisGap * 1.5,
                            height: axisThickness
                        )),
                        with: .color(axisColor)
                    )
                    
                    // rechter Marker (NOW-Strich)
                    let rightMarkerX = yAxisX + gridWidth + axisGap * 1.5
                    context.fill(
                        Rectangle().path(in: CGRect(x: rightMarkerX, y: xAxisY - 3, width: 1, height: 6)),
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
                    
                    // Y-Ticks (25/50/75)
                    let tickPercentages: [(Double, Bool)] = [(25, false), (50, true), (75, false)]
                    for (percentage, isSpecial) in tickPercentages {
                        let tickY: CGFloat
                        if percentage == 50 {
                            let row4Y = gridY + CGFloat(rows - 1 - 4) * (actualCellSize + actualSpacing)
                            let row5Y = gridY + CGFloat(rows - 1 - 5) * (actualCellSize + actualSpacing)
                            tickY = (row4Y + actualCellSize + row5Y) / 2
                        } else {
                            let rowFromBottom = Int(percentage / 10.0 - 0.5)
                            tickY = gridY + CGFloat(rows - 1 - rowFromBottom) * (actualCellSize + actualSpacing) + actualCellSize/2
                        }
                        let tickThickness = isSpecial ? axisThickness * 2 : axisThickness
                        let tickLength: CGFloat = isSpecial ? 5 : 3
                        context.fill(
                            Rectangle().path(in: CGRect(
                                x: yAxisX - tickLength,
                                y: tickY - tickThickness/2,
                                width: tickLength,
                                height: tickThickness
                            )),
                            with: .color(axisColor)
                        )
                    }
                    
                    // X-Ticks (zwischen Spalten)
                    let tickColumns = [4, 9, 14, 19, 24]
                    for colIndex in tickColumns {
                        let tickX = gridX + CGFloat(colIndex + 1) * (actualCellSize + actualSpacing) - actualSpacing/2
                        context.fill(
                            Rectangle().path(in: CGRect(x: tickX - axisThickness/2, y: xAxisY, width: axisThickness, height: 3)),
                            with: .color(axisColor)
                        )
                    }
                }
                .frame(
                    width: gridWidth + axisGap * 4 + 120,
                    height: gridHeight + axisGap * 4 + 60
                )
            }
        }
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
            TimeSeriesGridChart(currentValue: currentValue, maximum: maximum)
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
