import SwiftUI

struct TimeSeriesGridChart: View {
    let currentValue: Double
    let maximum: Double
    
    // Internal state to manage the rolling array of percentages
    @State private var percentageHistory: [Double] = []
    
    // Grid configuration
    private let rows = 10 // 10 percentage levels (0-10%, 10-20%, etc.)
    private let columns = 30 // 30 time ticks
    private let maxHistoryCount = 30
    private let spacingRatio: CGFloat = 0.2 // Spacing is 20% of cell size

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

    // Calculate cell size based on available space
    private func calculateCellSize(containerWidth: CGFloat, containerHeight: CGFloat) -> CGFloat {
        // Reserve space for labels and axes
        let labelSpace: CGFloat = 30
        let rightLabelSpace: CGFloat = 60 // Space for percentage label on the right
        let axisGap: CGFloat = 4

        // Calculate available width
        let availableWidth = containerWidth - (labelSpace + axisGap * 3 + rightLabelSpace)

        // Calculate available height
        let availableHeight = containerHeight - (labelSpace + axisGap * 3)

        // Calculate cell size based on width
        // Formula: availableWidth = (columns * cellSize) + ((columns - 1) * spacing)
        // Since spacing = cellSize * spacingRatio:
        // availableWidth = (columns * cellSize) + ((columns - 1) * cellSize * spacingRatio)
        // availableWidth = cellSize * (columns + (columns - 1) * spacingRatio)
        let widthBasedCellSize = availableWidth / (CGFloat(columns) + CGFloat(columns - 1) * spacingRatio)

        // Calculate cell size based on height (same formula)
        let heightBasedCellSize = availableHeight / (CGFloat(rows) + CGFloat(rows - 1) * spacingRatio)

        // Use the smaller of the two to ensure the grid fits in both dimensions
        return min(widthBasedCellSize, heightBasedCellSize)
    }

    private func calculateSpacing(for cellSize: CGFloat) -> CGFloat {
        return cellSize * spacingRatio
    }
    
    var body: some View {
        GeometryReader { geometry in
            // Calculate responsive cell size based on available space
            let cellSize = calculateCellSize(containerWidth: geometry.size.width, containerHeight: geometry.size.height)
            let spacing = calculateSpacing(for: cellSize)
            let gridWidth = CGFloat(columns) * cellSize + CGFloat(columns - 1) * spacing
            let gridHeight = CGFloat(rows) * cellSize + CGFloat(rows - 1) * spacing

            GridContentView(
                timeSeriesData: percentageHistory,
                currentPercentage: currentPercentage,
                cellSize: cellSize,
                spacing: spacing,
                gridWidth: gridWidth,
                gridHeight: gridHeight,
                rows: rows,
                columns: columns,
                gridColor: gridColor,
                fillColor: fillColor,
                axisColor: axisColor
            )
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
    let cellSize: CGFloat
    let spacing: CGFloat
    let gridWidth: CGFloat
    let gridHeight: CGFloat
    let rows: Int
    let columns: Int
    let gridColor: Color
    let fillColor: Color
    let axisColor: Color

    var body: some View {
        let axisThickness: CGFloat = 1
        let axisGap: CGFloat = cellSize * 0.5  // Gap between axis and grid
        
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
            // Define simple coordinate system with extra space for labels
            // Grid will be positioned with exactly axisGap (half cell) spacing from axes
            let labelSpace: CGFloat = 30
            let gridX = axisGap + axisGap + labelSpace
            let gridY = axisGap + labelSpace

            // Axis positions
            let yAxisX = axisGap + labelSpace  // Y-axis position
            let xAxisY = gridY + gridHeight + axisGap  // X-axis position (below grid)

            // Draw Y-axis (aligned with grid top)
            let yAxisTop = gridY
            context.fill(
                Rectangle().path(in: CGRect(
                    x: yAxisX - axisThickness/2,
                    y: yAxisTop,
                    width: axisThickness,
                    height: xAxisY - yAxisTop
                )),
                with: .color(axisColor)
            )

            // Draw tick mark at Y-axis top
            let tickLength: CGFloat = 3
            context.fill(
                Rectangle().path(in: CGRect(
                    x: yAxisX - tickLength,
                    y: yAxisTop,
                    width: tickLength,
                    height: axisThickness
                )),
                with: .color(axisColor)
            )

            // Draw X-axis
            context.fill(
                Rectangle().path(in: CGRect(
                    x: yAxisX,
                    y: xAxisY - axisThickness/2,
                    width: gridWidth + axisGap * 1.1,
                    height: axisThickness
                )),
                with: .color(axisColor)
            )

            // Draw "LOAD %" title at top-left above grid
            let titleLabelX = gridX + 10
            let titleLabelY = gridY - 10
            context.draw(
                Text("LOAD")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(axisColor),
                at: CGPoint(x: titleLabelX, y: titleLabelY)
            )

            // Draw grid cells
            for row in 0..<rows {
                for col in 0..<columns {
                    let x = gridX + CGFloat(col) * (cellSize + spacing)
                    let y = gridY + CGFloat(rows - 1 - row) * (cellSize + spacing)

                    let rect = CGRect(x: x, y: y, width: cellSize, height: cellSize)

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

            // Draw the percentage label at top-right above grid
            let percentageLabelX = gridX + gridWidth - 25
            let percentageLabelY = gridY - 12
            context.draw(
                Text("\(currentPercentage, specifier: "%.1f")%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white),
                at: CGPoint(x: percentageLabelX, y: percentageLabelY)
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
                    let row4Y = gridY + CGFloat(rows - 1 - 4) * (cellSize + spacing)
                    let row5Y = gridY + CGFloat(rows - 1 - 5) * (cellSize + spacing)
                    tickY = (row4Y + cellSize + row5Y) / 2 // Middle of the spacing
                } else {
                    let rowFromBottom = Int(tick.percentage / 10.0 - 0.5) // 25% -> row 2, 75% -> row 7
                    tickY = gridY + CGFloat(rows - 1 - rowFromBottom) * (cellSize + spacing) + cellSize/2
                }

                // Determine thickness based on whether it's the 50% marker
                let tickThickness = tick.isSpecial ? axisThickness * 1.5 : axisThickness
                let tickLength: CGFloat = 3

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
                let tickX = gridX + CGFloat(colIndex + 1) * (cellSize + spacing) - spacing/2

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
            let tickX = gridX + CGFloat(29 + 1) * (cellSize + spacing) - spacing
            context.fill(
                Rectangle().path(in: CGRect(
                    x: tickX - axisThickness/2,
                    y: xAxisY,
                    width: axisThickness,
                    height: 3
                )),
                with: .color(axisColor))
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
