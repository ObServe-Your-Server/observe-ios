//
//  ObServeApp.swift
//  ObServe
//
//  Created by Daniel Schatz on 16.07.25.
//

import SwiftUI
import SwiftData

@main
struct ObServeApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ServerModuleItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            OverView()
                .environment(\.font, .custom("IBM Plex Sans", size: 17))
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}
