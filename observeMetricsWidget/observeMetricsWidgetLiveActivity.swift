//
//  observeMetricsWidgetLiveActivity.swift
//  observeMetricsWidget
//
//  Created by Daniel Schatz on 16.10.25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct observeMetricsWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct observeMetricsWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: observeMetricsWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension observeMetricsWidgetAttributes {
    fileprivate static var preview: observeMetricsWidgetAttributes {
        observeMetricsWidgetAttributes(name: "World")
    }
}

extension observeMetricsWidgetAttributes.ContentState {
    fileprivate static var smiley: observeMetricsWidgetAttributes.ContentState {
        observeMetricsWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: observeMetricsWidgetAttributes.ContentState {
         observeMetricsWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: observeMetricsWidgetAttributes.preview) {
   observeMetricsWidgetLiveActivity()
} contentStates: {
    observeMetricsWidgetAttributes.ContentState.smiley
    observeMetricsWidgetAttributes.ContentState.starEyes
}
