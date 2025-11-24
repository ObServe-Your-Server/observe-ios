//
//  AppIntent.swift
//  observeMetricsWidget
//
//  Created by Daniel Schatz on 16.10.25.
//

import WidgetKit
import AppIntents

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Server Monitor Configuration" }
    static var description: IntentDescription { "Configure server monitoring widget." }

    @Parameter(title: "Server", description: "Select a server to monitor")
    var server: ServerEntity?

    @Parameter(title: "Metric", description: "Select a metric to display")
    var metric: MetricEntity?

    init() {
        print("ConfigurationAppIntent: Initializing")
    }

    init(server: ServerEntity?, metric: MetricEntity?) {
        print("ConfigurationAppIntent: Initializing with server: \(server?.displayString ?? "nil"), metric: \(metric?.displayString ?? "nil")")
        self.server = server
        self.metric = metric
    }

    // Computed properties for easy access
    var serverId: UUID? {
        return server?.serverId
    }

    var serverName: String {
        return server?.displayString ?? "No Server"
    }

    var metricType: String {
        return metric?.displayString ?? "CPU"
    }
}
