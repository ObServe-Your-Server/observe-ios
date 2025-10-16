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

    @Parameter(title: "Server Name", default: "HP Z440")
    var serverName: String
    
    @Parameter(title: "Metric Type", default: "CPU")
    var metricType: String
}
