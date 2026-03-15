import SwiftUI

struct TemperatureGraph: View {
    let temperature: Double?

    private let barHeight: CGFloat = 10
    private let slantOffset: CGFloat = 13

    private var activeColor: Color? {
        guard let t = temperature, t >= 30 else { return nil }
        if t < 55 { return Color(red: 0x3A / 255, green: 0x6F / 255, blue: 0x8F / 255) }
        if t < 75 { return Color(red: 0xB0 / 255, green: 0x8A / 255, blue: 0x3E / 255) }
        if t < 85 { return Color(red: 0xD4 / 255, green: 0x6A / 255, blue: 0x3A / 255) }
        return Color(red: 0xC2 / 255, green: 0x3B / 255, blue: 0x3B / 255)
    }

    private var filledCount: Int {
        guard let t = temperature else { return 0 }
        if t < 30 { return 0 }
        if t < 55 { return 1 }
        if t < 75 { return 2 }
        if t < 85 { return 3 }
        return 4
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("AVG CORE TEMPERATURE")
                    .foregroundColor(Color.gray)
                    .font(.plexSans(size: 12, weight: .medium))
                Spacer()
                Text(temperature != nil ? String(format: "%.2f", temperature!) : "--")
                    .foregroundColor(.white)
                    .font(.plexSans(size: 16, weight: .medium))
            }

            GeometryReader { geo in
                let totalWidth = geo.size.width
                let segWidth = totalWidth / 4.0
                Canvas { context, size in
                    let gap: CGFloat = 6
                    let totalGap = gap * 3 // 3 gaps between 4 segments
                    let adjustedSegWidth = (totalWidth - totalGap) / 4.0
                    for i in 0 ..< 4 {
                        let x = CGFloat(i) * (adjustedSegWidth + gap)
                        // Outer left/right edges are straight vertical; only internal dividers slant
                        let leftSlant: CGFloat = i == 0 ? 0 : slantOffset
                        let rightSlant: CGFloat = i == 3 ? 0 : slantOffset
                        let tl = CGPoint(x: x + leftSlant, y: 0)
                        let tr = CGPoint(x: x + adjustedSegWidth + rightSlant, y: 0)
                        let br = CGPoint(x: x + adjustedSegWidth, y: size.height)
                        let bl = CGPoint(x: x, y: size.height)
                        var path = Path()
                        path.move(to: tl)
                        path.addLine(to: tr)
                        path.addLine(to: br)
                        path.addLine(to: bl)
                        path.closeSubpath()
                        let isFilled = i < filledCount
                        if isFilled, let color = activeColor {
                            context.fill(path, with: .color(color.opacity(0.25)))
                            context.stroke(path, with: .color(color), lineWidth: 1)
                        } else {
                            context.fill(path, with: .color(Color.clear))
                            context.stroke(path, with: .color(Color("ObServeGray")), lineWidth: 1)
                        }
                    }
                }
            }
            .frame(height: barHeight)
        }
    }
}
