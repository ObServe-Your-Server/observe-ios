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
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent(), value: 75.0)
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        // In a real implementation, you would fetch the actual metric value here
        let mockValue = Double.random(in: 0...100)
        return SimpleEntry(date: Date(), configuration: configuration, value: mockValue)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []

        // Generate entries every 15 minutes with simulated server metrics
        let currentDate = Date()
        for minuteOffset in stride(from: 0, to: 60, by: 15) {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate)!
            // Simulate varying server metrics
            let simulatedValue = 50.0 + 30.0 * sin(Double(minuteOffset) * .pi / 30) + Double.random(in: -10...10)
            let clampedValue = max(0, min(100, simulatedValue))
            let entry = SimpleEntry(date: entryDate, configuration: configuration, value: clampedValue)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }

//    func relevances() async -> WidgetRelevances<ConfigurationAppIntent> {
//        // Generate a list containing the contexts this widget is relevant in.
//    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
    let value: Double
}

struct observeMetricsWidgetEntryView : View {
    var entry: Provider.Entry

    var body: some View {
        ZStack {
            Color.black
            
            VStack(spacing: 8) {
                // Header with server name and status indicator
                HStack {
                    Text(entry.configuration.serverName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                    
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                    
                    Spacer()
                    
                    // Large metric value in top right
                    Text("\(Int(entry.value))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                
                // Metric type label
                HStack {
                    Text("\(entry.configuration.metricType) %")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                
                Spacer()
                
                // Grid graph visualization
                WidgetGridGraph(value: entry.value, maxValue: 100)
                    .padding(.horizontal, 12)
                
                Spacer()
            }
        }
    }
}

struct observeMetricsWidget: Widget {
    let kind: String = "observeMetricsWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            observeMetricsWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var hpZ440CPU: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.serverName = "HP Z440"
        intent.metricType = "CPU"
        return intent
    }
    
    fileprivate static var serverRAM: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.serverName = "Server 01"
        intent.metricType = "RAM"
        return intent
    }
}

#Preview(as: .systemSmall) {
    observeMetricsWidget()
} timeline: {
    SimpleEntry(date: .now, configuration: .hpZ440CPU, value: 85.0)
    SimpleEntry(date: .now, configuration: .serverRAM, value: 62.0)
}
