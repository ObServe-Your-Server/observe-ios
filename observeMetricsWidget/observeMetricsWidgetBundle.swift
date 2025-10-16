//
//  observeMetricsWidgetBundle.swift
//  observeMetricsWidget
//
//  Created by Daniel Schatz on 16.10.25.
//

import WidgetKit
import SwiftUI

@main
struct observeMetricsWidgetBundle: WidgetBundle {
    var body: some Widget {
        observeMetricsWidget()
        observeMetricsWidgetControl()
        observeMetricsWidgetLiveActivity()
    }
}
