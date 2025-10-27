//
//  observeMetricsWidget.swift
//  observeMetricsWidget
//
//  Created by Daniel Schatz on 16.10.25.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(
            date: Date(),
            configuration: ConfigurationAppIntent(),
            value: 0.0,
            isConnected: true,
            isHealthy: true,
            history: [],
            uptime: 0,
            machineType: "SERVER",
            allMetrics: [:],
            rawMetricValues: [:]
        )
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        // For snapshot, use cached data or placeholder
        guard let serverId = configuration.serverId else {
            return placeholder(in: context)
        }

        let server = SharedStorageManager.shared.getServer(byId: serverId)
        let cachedMetric = SharedStorageManager.shared.loadMetricData(
            serverId: serverId,
            metricType: configuration.metricType
        )

        // Load all cached metrics for dynamic display
        var allMetrics: [String: Double] = [:]
        for metricType in ["CPU", "RAM", "Storage", "Network In", "Network Out"] {
            if let cached = SharedStorageManager.shared.loadMetricData(serverId: serverId, metricType: metricType) {
                allMetrics[metricType] = cached.value
            }
        }

        return SimpleEntry(
            date: Date(),
            configuration: configuration,
            value: cachedMetric?.value,
            isConnected: server?.isConnected ?? false,
            isHealthy: server?.isHealthy ?? false,
            history: cachedMetric?.history ?? [],
            uptime: server?.uptime,
            machineType: server?.type ?? "SERVER",
            allMetrics: allMetrics,
            rawMetricValues: [:]
        )
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let currentDate = Date()

        // Check if server is configured
        guard let serverId = configuration.serverId else {
            let entry = SimpleEntry(
                date: currentDate,
                configuration: configuration,
                value: nil,
                isConnected: false,
                isHealthy: false,
                history: [],
                uptime: nil,
                machineType: "SERVER",
                allMetrics: [:],
                rawMetricValues: [:]
            )
            return Timeline(entries: [entry], policy: .after(currentDate.addingTimeInterval(300)))
        }

        // Load latest server status from shared storage
        guard let server = SharedStorageManager.shared.getServer(byId: serverId) else {
            print("Widget: Server not found in shared storage")
            let entry = SimpleEntry(
                date: currentDate,
                configuration: configuration,
                value: nil,
                isConnected: false,
                isHealthy: false,
                history: [],
                uptime: nil,
                machineType: "SERVER",
                allMetrics: [:],
                rawMetricValues: [:]
            )
            return Timeline(entries: [entry], policy: .after(currentDate.addingTimeInterval(300)))
        }

        // Load cached data first for immediate display
        let cachedMetric = SharedStorageManager.shared.loadMetricData(
            serverId: serverId,
            metricType: configuration.metricType
        )

        print("Widget: Cached value for \(configuration.metricType): \(cachedMetric?.value.description ?? "none")")

        // Check if server is connected before attempting fetch
        guard server.isConnected else {
            print("Widget: Server is offline, displaying --- and empty grid")
            // Display "---" and empty grid when server is offline (ignore cache)
            let entry = SimpleEntry(
                date: currentDate,
                configuration: configuration,
                value: nil,
                isConnected: false,
                isHealthy: server.isHealthy,
                history: [],
                uptime: nil,
                machineType: server.type,
                allMetrics: [:],
                rawMetricValues: [:]
            )
            // Retry in 1 minute when offline
            return Timeline(entries: [entry], policy: .after(currentDate.addingTimeInterval(60)))
        }

        // Fetch ALL metrics for comprehensive widget display
        print("Widget: Fetching all metrics for dynamic display...")
        let fetcher = WidgetMetricFetcher(server: server)
        let allFetchedMetrics = await fetcher.fetchAllMetrics()
        let rawMetricValues = await fetcher.fetchRawMetricValues()

        // Get the value for the selected metric
        let displayValue = allFetchedMetrics[configuration.metricType] ?? cachedMetric?.value

        // Load all cached metrics as fallback
        var allMetrics: [String: Double] = [:]
        for metricType in ["CPU", "RAM", "Storage", "Network In", "Network Out"] {
            // Use fresh data if available, otherwise use cache
            if let freshValue = allFetchedMetrics[metricType] {
                allMetrics[metricType] = freshValue
            } else if let cached = SharedStorageManager.shared.loadMetricData(serverId: serverId, metricType: metricType) {
                allMetrics[metricType] = cached.value
            }
        }

        let entry = SimpleEntry(
            date: currentDate,
            configuration: configuration,
            value: displayValue,
            isConnected: server.isConnected,
            isHealthy: server.isHealthy,
            history: cachedMetric?.history ?? [],
            uptime: server.uptime,
            machineType: server.type,
            allMetrics: allMetrics,
            rawMetricValues: rawMetricValues
        )

        // Save fresh metrics to cache
        for (metricType, value) in allFetchedMetrics {
            saveMetricToCache(serverId: serverId, metricType: metricType, value: value)
            print("Widget: Saved fresh \(metricType) = \(value)")
        }

        if displayValue != nil {
            print("Widget: Using fresh data for \(configuration.metricType): \(displayValue!)")
        } else if let cachedValue = cachedMetric?.value {
            print("Widget: Fetch failed, falling back to cached data: \(cachedValue)")
        } else {
            print("Widget: No fresh data or cache available for \(configuration.metricType)")
        }

        // Update every 1 minute for active monitoring
        let nextUpdate = currentDate.addingTimeInterval(60)
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchMetricValue(server: SharedServer, metricType: String) async -> Double? {
        let fetcher = WidgetMetricFetcher(server: server)
        let value = await fetcher.fetchMetric(type: metricType)

        if let value = value {
            print("Widget: Fetched \(metricType) = \(value)")
        } else {
            print("Widget: Failed to fetch \(metricType)")
        }

        return value
    }

    private func saveMetricToCache(serverId: UUID, metricType: String, value: Double) {
        let cachedMetric = SharedStorageManager.shared.loadMetricData(
            serverId: serverId,
            metricType: metricType
        )

        var history = cachedMetric?.history ?? []
        history.append(value)
        // Keep history up to 34 to support medium widget size
        if history.count > 34 {
            history.removeFirst()
        }

        let metricData = SharedMetricData(
            serverId: serverId,
            metricType: metricType,
            value: value,
            timestamp: Date(),
            history: history
        )
        SharedStorageManager.shared.saveMetricData(metricData)
        print("Widget: Saved \(metricType) to cache")
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let value: Double? // nil when server is offline - value for selected metric
    let isConnected: Bool
    let isHealthy: Bool
    let history: [Double] // Historical percentage values for grid graph
    let uptime: TimeInterval? // Server uptime in seconds
    let machineType: String // Server machine type (SERVER, CUBE, etc.)
    let allMetrics: [String: Double] // All fetched metric values for dynamic display
    let rawMetricValues: [String: [String: Double]] // Raw values (used/total) for RAM and Storage
}

struct observeMetricsWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily

    // Determine status dot color based on connection and health
    private var statusColor: Color {
        if !entry.isConnected {
            return .red
        } else if !entry.isHealthy {
            return .orange
        } else {
            return .green
        }
    }

    // Display value or "---" when offline
    private var displayValue: String {
        if let value = entry.value {
            // Show "<1" for values between 0 and 1 (exclusive)
            if value > 0 && value < 1 {
                return "<1"
            }
            return "\(Int(value))"
        } else {
            return "---"
        }
    }

    // Determine columns based on widget size
    private var gridColumns: Int {
        switch widgetFamily {
        case .systemMedium, .systemLarge:
            return 34
        default:
            return 14
        }
    }

    var body: some View {
        ZStack {
            Color.black

            if widgetFamily == .systemLarge {
                // Large widget: comprehensive dashboard view
                LargeWidgetView(entry: entry, statusColor: statusColor, displayValue: displayValue, gridColumns: gridColumns)
            } else {
                // Small and Medium widgets: original layout
                VStack(spacing: 5) {
                    // Header with server name, status indicator, and metric value
                    HStack(alignment: .top, spacing: 0) {
                        VStack(alignment: .leading, spacing: 2) {
                            // Left side: Server name and status
                            HStack(spacing: 6) {
                                Text(entry.configuration.serverName)
                                    .font(.custom("IBM Plex Sans", size: 16))
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .truncationMode(.tail)

                                Circle()
                                    .fill(statusColor)
                                    .frame(width: 8, height: 8)
                            }
                            .layoutPriority(-1)

                            // Metric type label
                            Text("\(entry.configuration.metricType) %")
                                .font(.custom("IBM Plex Sans", size: 14))
                                .foregroundColor(Color(red: 0x80/255, green: 0x80/255, blue: 0x80/255))
                        }

                        Spacer(minLength: 6)

                        // Right side: Large metric value or "---"
                        Text(displayValue)
                            .font(.custom("IBM Plex Sans", size: 30))
                            .foregroundColor(.white)
                            .tracking(-1.0)
                            .layoutPriority(1)
                    }
                    .padding(.horizontal, 0)

                    // Grid graph visualization with dynamic columns based on widget size
                    WidgetGridGraph(value: entry.value, maxValue: 100, columns: gridColumns, history: entry.history)
                }
            }
        }
    }
}

// MARK: - Large Widget View

struct LargeWidgetView: View {
    let entry: SimpleEntry
    let statusColor: Color
    let displayValue: String
    let gridColumns: Int

    // Determine which two metrics to display (excluding the selected one)
    private var displayMetrics: (String, String) {
        switch entry.configuration.metricType {
        case "CPU":
            return ("RAM", "Storage")
        case "RAM":
            return ("CPU", "Storage")
        case "Storage":
            return ("CPU", "RAM")
        default:
            return ("RAM", "Storage")
        }
    }

    // Server icon based on type and status
    private var serverIconName: String {
        let machineType = WidgetMachineType(fromString: entry.machineType) ?? .server
        let isOnline = entry.isConnected && entry.isHealthy
        return machineType.imageName(isOnline: isOnline)
    }

    var body: some View {
        VStack(spacing: 6) {
            // Row 1: Server name + status indicator
            HStack(spacing: 6) {
                Text(entry.configuration.serverName)
                    .font(.custom("IBM Plex Sans", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)

                Spacer()
            }

            // Row 2: Running time + Server icon
            HStack(alignment: .center, spacing: 12) {
                // Left: Running time (UpdateLabel style)
                VStack(alignment: .leading, spacing: 4) {
                    Text("RUNNING FOR")
                        .foregroundColor(Color.gray)
                        .font(.custom("IBM Plex Sans", size: 12))
                        .fontWeight(.medium)

                    Text(formatUptime(entry.uptime))
                        .foregroundColor(.white)
                        .font(.custom("IBM Plex Sans", size: 18))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Right: Server icon (left-aligned in right column)
                Image(serverIconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Row 3: Two dynamic metrics (exclude grid metric)
            HStack(spacing: 12) {
                // Left metric - using WidgetUpdateLabel
                metricView(for: displayMetrics.0)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Right metric - using WidgetUpdateLabel
                metricView(for: displayMetrics.1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Row 4: Network metrics (always visible)
            HStack(spacing: 12) {
                WidgetNetworkLabel(
                    label: "IN",
                    value: entry.allMetrics["Network In"],
                    decimalPlaces: 0
                )
                .frame(maxWidth: .infinity, alignment: .leading)

                WidgetNetworkLabel(
                    label: "OUT",
                    value: entry.allMetrics["Network Out"],
                    decimalPlaces: 0
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Row 5: Grid graph section
            VStack(spacing: 5) {
                // Top bar: Metric label + percentage value
                HStack(alignment: .bottom, spacing: 0) {
                    // Left: Metric type label
                    Text("\(entry.configuration.metricType) %")
                        .font(.custom("IBM Plex Sans", size: 14))
                        .foregroundColor(Color.gray)

                    Spacer(minLength: 6)

                    // Right: Percentage value
                    Text(displayValue)
                        .font(.custom("IBM Plex Sans", size: 30))
                        .foregroundColor(.white)
                        .tracking(-1.0)
                        .layoutPriority(1)
                }

                // Grid graph visualization
                WidgetGridGraph(value: entry.value, maxValue: 100, columns: gridColumns, history: entry.history)
            }
        }
    }

    // Helper to create metric views with proper styling
    @ViewBuilder
    private func metricView(for metricType: String) -> some View {
        if metricType == "CPU" {
            // CPU shows percentage only
            WidgetUpdateLabel(
                label: "CPU USAGE",
                value: entry.allMetrics["CPU"] ?? 0,
                max: 0,
                unit: "%",
                decimalPlaces: 0,
                showPercent: false
            )
        } else if metricType == "RAM" {
            // RAM shows used / total GB with progress bar
            let ramValues = entry.rawMetricValues["RAM"]
            let used = ramValues?["used"] ?? 0
            let total = ramValues?["total"] ?? 0
            
            WidgetUpdateLabel(
                label: "MEMORY",
                value: used,
                max: total,
                unit: "GB",
                decimalPlaces: 2,
                showPercent: true
            )
        } else if metricType == "Storage" {
            // Storage shows used / total GB with progress bar
            let storageValues = entry.rawMetricValues["Storage"]
            let used = storageValues?["used"] ?? 0
            let total = storageValues?["total"] ?? 0
            
            WidgetUpdateLabel(
                label: "STORAGE",
                value: used,
                max: total,
                unit: "GB",
                decimalPlaces: 2,
                showPercent: true
            )
        }
    }
}

struct observeMetricsWidget: Widget {
    let kind: String = "observeMetricsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            observeMetricsWidgetEntryView(entry: entry)
                .containerBackground(Color.black, for: .widget)
        }
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    observeMetricsWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), value: 85.0, isConnected: true, isHealthy: true, history: [45, 50, 55, 60, 65, 70, 75, 80, 85], uptime: 435372, machineType: "SERVER", allMetrics: ["CPU": 85.0, "RAM": 24.4, "Storage": 63.0, "Network In": 775168, "Network Out": 32768], rawMetricValues: ["RAM": ["used": 23.4, "total": 96.0], "Storage": ["used": 315.0, "total": 500.0]])
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), value: 100.0, isConnected: true, isHealthy: true, history: [60, 65, 70, 75, 80, 85, 90, 95, 100], uptime: 435372, machineType: "SERVER", allMetrics: ["CPU": 100.0, "RAM": 96.0, "Storage": 85.0, "Network In": 1048576, "Network Out": 524288], rawMetricValues: ["RAM": ["used": 92.2, "total": 96.0], "Storage": ["used": 425.0, "total": 500.0]])
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), value: nil, isConnected: false, isHealthy: false, history: [], uptime: nil, machineType: "SERVER", allMetrics: [:], rawMetricValues: [:])
}

#Preview(as: .systemMedium) {
    observeMetricsWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), value: 85.0, isConnected: true, isHealthy: true, history: [45, 50, 55, 60, 65, 70, 75, 80, 85], uptime: 435372, machineType: "CUBE", allMetrics: ["CPU": 85.0, "RAM": 24.4, "Storage": 63.0, "Network In": 775168, "Network Out": 32768], rawMetricValues: ["RAM": ["used": 23.4, "total": 96.0], "Storage": ["used": 315.0, "total": 500.0]])
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), value: 100.0, isConnected: true, isHealthy: true, history: [60, 65, 70, 75, 80, 85, 90, 95, 100], uptime: 435372, machineType: "CUBE", allMetrics: ["CPU": 100.0, "RAM": 96.0, "Storage": 85.0, "Network In": 1048576, "Network Out": 524288], rawMetricValues: ["RAM": ["used": 92.2, "total": 96.0], "Storage": ["used": 425.0, "total": 500.0]])
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), value: nil, isConnected: false, isHealthy: false, history: [], uptime: nil, machineType: "CUBE", allMetrics: [:], rawMetricValues: [:])
}

#Preview(as: .systemLarge) {
    observeMetricsWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), value: 85.0, isConnected: true, isHealthy: true, history: [45, 50, 55, 60, 65, 70, 75, 80, 85], uptime: 435372, machineType: "TOWER", allMetrics: ["CPU": 85.0, "RAM": 24.4, "Storage": 63.0, "Network In": 775168, "Network Out": 32768], rawMetricValues: ["RAM": ["used": 23.4, "total": 96.0], "Storage": ["used": 315.0, "total": 500.0]])
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), value: 100.0, isConnected: true, isHealthy: true, history: [60, 65, 70, 75, 80, 85, 90, 95, 100], uptime: 435372, machineType: "TOWER", allMetrics: ["CPU": 100.0, "RAM": 96.0, "Storage": 85.0, "Network In": 1048576, "Network Out": 524288], rawMetricValues: ["RAM": ["used": 92.2, "total": 96.0], "Storage": ["used": 425.0, "total": 500.0]])
    SimpleEntry(date: .now, configuration: ConfigurationAppIntent(), value: nil, isConnected: false, isHealthy: false, history: [], uptime: nil, machineType: "TOWER", allMetrics: [:], rawMetricValues: [:])
}
