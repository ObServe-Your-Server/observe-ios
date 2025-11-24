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
    @StateObject private var authManager = AuthenticationManager()
    @State private var isCheckingAuth = true
    @Environment(\.scenePhase) private var scenePhase

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
            ZStack {
                if isCheckingAuth {
                    // Loading state while checking authentication
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading...")
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.ignoresSafeArea())
                    .environment(\.font, .custom("IBM Plex Sans", size: 17))
                    .preferredColorScheme(.dark)
                } else if authManager.isAuthenticated {
                    OverView()
                        .environmentObject(authManager)
                        .environment(\.font, .custom("IBM Plex Sans", size: 17))
                        .preferredColorScheme(.dark)
                } else {
                    LoginView()
                        .environmentObject(authManager)
                        .environment(\.font, .custom("IBM Plex Sans", size: 17))
                        .preferredColorScheme(.dark)
                        .background(Color.black.ignoresSafeArea())
                }
            }
            .onAppear {
                // Validate tokens on app startup
                authManager.validateAndRefreshIfNeeded { success in
                    isCheckingAuth = false
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                // Manage refresh timer based on app state
                if newPhase == .active && authManager.isAuthenticated {
                    authManager.startRefreshTimer()
                } else if newPhase == .background || newPhase == .inactive {
                    authManager.stopRefreshTimer()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
