import SwiftUI

struct TimeSeriesGridChart: View {
    let currentValue: Double
    let maximum: Double
    
    // Internal state to manage the rolling array of percentages
    @State private var percentageHistory: [Double] = []
    
    // Grid configuration
    private let rows = 10 // 10 percentage levels (0-10%, 10-20%, etc.)
    private let columns = 30 // 30 time ticks
    private let cellSize: CGFloat = 10
    private let maxHistoryCount = 30
    
    private var cellSpacing: CGFloat {
        cellSize * 0.2 // 20% of cell size (4px when cellSize is 20)
    }
    
    // Calculate current percentage
    private var currentPercentage: Double {
        guard maximum > 0 else { return 0 }
        return min(max((currentValue / maximum) * 100, 0), 100)
    }
    
    // Colors
    private let gridColor = Color(red: 0x80/255, green: 0x80/255, blue: 0x80/255).opacity(0.2) // #808080 with 20% opacity
    private let fillColor = Color.white // #FFFFFF
    private let highlightColor = Color.blue
    private let axisColor = Color(red: 0x80/255, green: 0x80/255, blue: 0x80/255)
    
    // Computed properties to help the compiler
    private func calculateActualCellSize(for width: CGFloat) -> CGFloat {
        let availableWidth = width * 0.6 // Leave more room for labels on both sides
        let totalSpacingWidth = CGFloat(columns - 1) * (cellSize * 0.2)
        let calculatedCellSize = (availableWidth - totalSpacingWidth) / CGFloat(columns)
        return min(cellSize, calculatedCellSize)
    }
    
    private func calculateActualSpacing(for cellSize: CGFloat) -> CGFloat {
        return cellSize * 0.2
    }
    
    private func calculateGridHeight(cellSize: CGFloat, spacing: CGFloat) -> CGFloat {
        return CGFloat(rows) * cellSize + CGFloat(rows - 1) * spacing
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Calculate dimensions for proper positioning
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
        .onChange(of: currentValue) { oldValue, newValue in
            updatePercentageHistory()
        }
        .onChange(of: maximum) { oldValue, newValue in
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
        
        // Keep only the last 30 values
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
        let gridWidth = CGFloat(columns) * actualCellSize + CGFloat(columns - 1) * actualSpacing
        let axisThickness: CGFloat = 1
        let axisGap: CGFloat = actualCellSize * 0.5  // Gap between axis and grid
        
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
        
        HStack(spacing: 0) {
            Spacer()
            
            Canvas { context, size in
                // Define simple coordinate system with extra space for labels
                // Grid will be positioned with exactly axisGap (half cell) spacing from axes
                let labelSpace: CGFloat = 30
                let gridX = axisGap + axisGap + labelSpace
                let gridY = axisGap + labelSpace
                
                // Axis positions
                let yAxisX = axisGap + labelSpace  // Y-axis position
                let xAxisY = gridY + gridHeight + axisGap  // X-axis position (below grid)
                
                // Draw Y-axis
                context.fill(
                    Rectangle().path(in: CGRect(
                        x: yAxisX - axisThickness/2,
                        y: labelSpace,
                        width: axisThickness,
                        height: xAxisY + 1/10 * axisGap - labelSpace
                    )),
                    with: .color(axisColor)
                )
                
                // Draw X-axis
                context.fill(
                    Rectangle().path(in: CGRect(
                        x: yAxisX,
                        y: xAxisY - axisThickness/2,
                        width: gridWidth + axisGap * 1.5,
                        height: axisThickness
                    )),
                    with: .color(axisColor)
                )
                
                // Draw end markers
                // Top Y-axis marker
                context.fill(
                    Rectangle().path(in: CGRect(x: yAxisX - 3, y: labelSpace, width: 6, height: 1)),
                    with: .color(axisColor)
                )
                
                // "100" label at the top Y-axis marker
                context.draw(
                    Text("100")
                        .font(.system(size: 10))
                        .foregroundColor(Color(axisColor)),
                    at: CGPoint(x: yAxisX - 15, y: labelSpace + 1)
                )
                
                // Right X-axis marker
                let rightMarkerX = yAxisX + gridWidth + axisGap * 1.5
                context.fill(
                    Rectangle().path(in: CGRect(x: rightMarkerX, y: xAxisY - 3, width: 1, height: 6)),
                    with: .color(axisColor)
                )
                
                // "NOW" label below the right X-axis marker
                context.draw(
                    Text("NOW")
                        .font(.system(size: 10))
                        .foregroundColor(Color(axisColor)),
                    at: CGPoint(x: rightMarkerX + 2, y: xAxisY + 10)
                )
                
                // Draw grid cells
                for row in 0..<rows {
                    for col in 0..<columns {
                        let x = gridX + CGFloat(col) * (actualCellSize + actualSpacing)
                        let y = gridY + CGFloat(rows - 1 - row) * (actualCellSize + actualSpacing)
                        
                        let rect = CGRect(x: x, y: y, width: actualCellSize, height: actualCellSize)
                        
                        var cellColor = gridColor
                        let usageValue = displayData[col]
                        let percentageLevel = Double(row) * 10.0
                        
                        if usageValue > percentageLevel {
                            cellColor = fillColor
                        }
                        
                        context.fill(
                            Rectangle().path(in: rect),
                            with: .color(cellColor)
                        )
                    }
                }
                
                // Calculate position for the side percentage label
                let percentageRowFromBottom = currentPercentage / 10.0
                let clampedRowFromBottom = max(0, min(Double(rows), percentageRowFromBottom))
                
                // Calculate the Y position for the percentage label
                let labelY: CGFloat
                if clampedRowFromBottom >= Double(rows) {
                    labelY = gridY
                } else {
                    // Position based on the percentage level
                    let rowIndex = rows - 1 - Int(clampedRowFromBottom)
                    let fractionalPart = clampedRowFromBottom - floor(clampedRowFromBottom)
                    let baseY = gridY + CGFloat(rowIndex) * (actualCellSize + actualSpacing)
                    
                    // Interpolate within the cell based on the fractional part
                    labelY = baseY + actualCellSize/2 - CGFloat(fractionalPart) * (actualCellSize + actualSpacing)
                }
                
                // Draw the side percentage label
                let sidePercentageLabelX = gridX + gridWidth + axisGap * 9
                context.draw(
                    Text("\(currentPercentage, specifier: "%.1f")%")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white),
                    at: CGPoint(x: sidePercentageLabelX, y: labelY)
                )
                
                let tickPercentages: [(percentage: Double, isSpecial: Bool)] = [
                    (25.0, false),
                    (50.0, true),  // 50% marker is special (thicker)
                    (75.0, false)
                ]
                
                for tick in tickPercentages {
                    let tickY: CGFloat
                    
                    if tick.percentage == 50.0 {
                        // 50% should be between 5th and 6th cells (between row 4 and 5)
                        // Position it in the spacing between these cells
                        let row4Y = gridY + CGFloat(rows - 1 - 4) * (actualCellSize + actualSpacing)
                        let row5Y = gridY + CGFloat(rows - 1 - 5) * (actualCellSize + actualSpacing)
                        tickY = (row4Y + actualCellSize + row5Y) / 2 // Middle of the spacing
                    } else {
                        let rowFromBottom = Int(tick.percentage / 10.0 - 0.5) // 25% -> row 2, 75% -> row 7
                        tickY = gridY + CGFloat(rows - 1 - rowFromBottom) * (actualCellSize + actualSpacing) + actualCellSize/2
                    }
                    
                    // Determine thickness based on whether it's the 50% marker
                    let tickThickness = tick.isSpecial ? axisThickness * 2 : axisThickness
                    let tickLength: CGFloat = tick.isSpecial ? 5 : 3
                    
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
                
                // X-axis tick marks for columns 5, 10, 15, 20, 25 (positioned between cells)
                let tickColumns = [4, 9, 14, 19, 24]
                for colIndex in tickColumns {
                    let tickX = gridX + CGFloat(colIndex + 1) * (actualCellSize + actualSpacing) - actualSpacing/2
                    
                    context.fill(
                        Rectangle().path(in: CGRect(
                            x: tickX - axisThickness/2,
                            y: xAxisY,
                            width: axisThickness,
                            height: 3
                        )),
                        with: .color(axisColor)
                    )
                }
            }
            .frame(
                width: gridWidth + axisGap * 4 + 120,
                height: gridHeight + axisGap * 4 + 60
            )
            
            Spacer()
        }
    }
}

// Separate view for the percentage label
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
            TimeSeriesGridChart(
                currentValue: currentValue,
                maximum: maximum
            )
            .preferredColorScheme(.dark)
            
            // Control section for demo
            VStack(spacing: 20) {
                HStack {
                    Text("Current Value: \(currentValue, specifier: "%.1f")")
                        .foregroundColor(.white)
                    Slider(value: $currentValue, in: 0...maximum)
                        .accentColor(.blue)
                }
                .padding(.horizontal)
                
                HStack {
                    Text("Maximum: \(maximum, specifier: "%.1f")")
                        .foregroundColor(.white)
                    Slider(value: $maximum, in: 50...200)
                        .accentColor(.blue)
                }
                .padding(.horizontal)
                
                // Demo buttons
                HStack {
                    Button("Low (25%)") {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentValue = maximum * 0.25
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    
                    Button("Medium (50%)") {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentValue = maximum * 0.5
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    
                    Button("High (85%)") {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentValue = maximum * 0.85
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                }
            }
            .background(Color.black)
        }
        .background(Color.black)
        .onAppear {
            // Simulate real-time updates with varying values
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    // Simulate changing values over time
                    currentValue = Double.random(in: 10...maximum)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
