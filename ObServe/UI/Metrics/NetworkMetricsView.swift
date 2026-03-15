import SwiftUI

private func formatBytesUnit(_ bytes: Double) -> String {
    let kb = bytes / 1024.0
    return kb >= 1024.0 ? "MB/S" : "KB/S"
}

private func formatBytesNumber(_ bytes: Double) -> String {
    let kb = bytes / 1024.0
    return kb >= 1024.0 ? String(format: "%.2f", kb / 1024.0) : String(format: "%.0f", kb)
}

struct NetworkMetricsView: View {
    @ObservedObject var metricsManager: MetricsManager
    @State private var isExpanded: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 12)

                if isExpanded {
                    // Header row — gray box style
                    HStack {
                        Text("IP")
                            .foregroundColor(Color.gray)
                            .font(.plexSans(size: 12, weight: .medium))
                        Spacer()
                        Text(metricsManager.localIp ?? "Unknown")
                            .foregroundColor(.white)
                            .font(.plexSans(size: 14, weight: .medium))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 0).fill(Color(red: 0.102, green: 0.102, blue: 0.102)))
                }

                // IN / OUT — always visible
                HStack(spacing: 18) {
                    HStack {
                        Text("IN \(formatBytesUnit(metricsManager.avgNetworkIn))")
                            .foregroundColor(Color.gray)
                            .font(.plexSans(size: 10, weight: .medium))
                        Spacer()
                        Text(formatBytesNumber(metricsManager.avgNetworkIn))
                            .foregroundColor(.white)
                            .font(.plexSans(size: 18, weight: .bold))
                    }
                    HStack {
                        Text("OUT \(formatBytesUnit(metricsManager.avgNetworkOut))")
                            .foregroundColor(Color.gray)
                            .font(.plexSans(size: 10, weight: .medium))
                        Spacer()
                        Text(formatBytesNumber(metricsManager.avgNetworkOut))
                            .foregroundColor(.white)
                            .font(.plexSans(size: 18, weight: .bold))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if isExpanded {
                    // Ping row
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("PING MS")
                                .foregroundColor(Color.gray)
                                .font(.plexSans(size: 10, weight: .medium))
                            Spacer()
                            Text(metricsManager.ping.map { String(format: "%.0f", $0) } ?? "—")
                                .foregroundColor(.white)
                                .font(.plexSans(size: 18, weight: .bold))
                        }
                        PingHistoryBar(history: metricsManager.pingHistory)
                    }
                    .padding(.top, 4)

                    // Downlink / Upload two-column row
                    HStack(spacing: 18) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("DOWN MB/S")
                                    .foregroundColor(Color.gray)
                                    .font(.plexSans(size: 10, weight: .medium))
                                Spacer()
                                Image(systemName: "arrow.down.right")
                                    .foregroundColor(Color.gray)
                                    .font(.plexSans(size: 12, weight: .medium))
                                Text(metricsManager.downloadSpeed.map { String(format: "%.0f", $0) } ?? "—")
                                    .foregroundColor(.white)
                                    .font(.plexSans(size: 18, weight: .bold))
                            }
                            SpeedMeter(current: metricsManager.downloadSpeed ?? 0)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("UP MB/S")
                                    .foregroundColor(Color.gray)
                                    .font(.plexSans(size: 10, weight: .medium))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .foregroundColor(Color.gray)
                                    .font(.plexSans(size: 12, weight: .medium))
                                Text(metricsManager.uploadSpeed.map { String(format: "%.0f", $0) } ?? "—")
                                    .foregroundColor(.white)
                                    .font(.plexSans(size: 18, weight: .bold))
                            }
                            SpeedMeter(current: metricsManager.uploadSpeed ?? 0)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 10)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
            )
            .overlay(alignment: .topLeading) {
                HStack {
                    Text("NETWORK")
                        .foregroundColor(.white)
                        .font(.plexSans(size: 14, weight: .medium))
                }
                .padding(10)
                .background(Color.black)
                .padding(.top, -18)
                .padding(.leading, 10)
            }
            .overlay(alignment: .bottomTrailing) {
                ExpandCornerIndicator()
            }
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }
        }
        .padding(.vertical, 20)
    }
}

private struct PingHistoryBar: View {
    let history: [MetricsManager.PingEntry]
    private let slotCount = 10
    private let failThreshold: Double = 300.0

    private func isFailed(_ entry: MetricsManager.PingEntry?) -> Bool {
        guard let entry, let value = entry.value else { return true }
        return value > failThreshold
    }

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0 ..< slotCount, id: \.self) { i in
                let offset = slotCount - history.count
                let entry: MetricsManager.PingEntry? = i >= offset ? history[i - offset] : nil
                let isCurrent = (i == slotCount - 1)
                let failed = isFailed(entry)
                let strokeColor: Color = isCurrent
                    ? .white
                    : (failed ? Color(red: 0xD4 / 255, green: 0x6A / 255, blue: 0x3A / 255) : Color("ObServeGray"))

                Rectangle()
                    .fill(strokeColor.opacity(0.25))
                    .overlay(Rectangle().stroke(strokeColor, lineWidth: 1))
                    .frame(height: 10)
            }
        }
    }
}

private struct SpeedMeter: View {
    let current: Double
    private let segments = 10
    private let tiers: [Double] = [10, 50, 100, 500, 1000]

    private var maximum: Double {
        tiers.first(where: { $0 > current }) ?? tiers.last!
    }

    private var filledSegments: Int {
        min(Int((current / maximum) * Double(segments)), segments)
    }

    var body: some View {
        Canvas { context, size in
            let strokeWidth: CGFloat = 0.5
            let spacing: CGFloat = 1
            let totalSpacing = spacing * CGFloat(segments - 1)
            let segWidth = (size.width - totalSpacing) / CGFloat(segments)

            // Draw filled segments edge-to-edge
            for i in 0 ..< segments {
                let x = CGFloat(i) * (segWidth + spacing)
                let rect = CGRect(x: x, y: 0, width: segWidth, height: size.height)
                if i < filledSegments {
                    context.fill(
                        Rectangle().path(in: rect),
                        with: .color(Color(red: 0xCF / 255, green: 0xCF / 255, blue: 0xCF / 255))
                    )
                }
            }

            // Draw continuous outer stroke on top
            let outerRect = CGRect(
                x: strokeWidth / 2,
                y: strokeWidth / 2,
                width: size.width - strokeWidth,
                height: size.height - strokeWidth
            )
            context.stroke(
                Rectangle().path(in: outerRect),
                with: .color(Color("ObServeGray")),
                lineWidth: strokeWidth
            )
        }
        .frame(height: 9)
    }
}

#Preview {
    let sampleServer = ServerModuleItem(machineUUID: UUID(), name: "Test Server", type: "Server")
    let metricsManager = MetricsManager(server: sampleServer)

    NetworkMetricsView(metricsManager: metricsManager)
        .background(Color.black)
}
