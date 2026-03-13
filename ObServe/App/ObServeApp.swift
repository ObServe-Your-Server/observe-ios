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

    private var isDemoMode: Bool {
        ProcessInfo.processInfo.arguments.contains("SNAPSHOT_DEMO_MODE")
    }
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ServerModuleItem.self
        ])
        let isDemoMode = ProcessInfo.processInfo.arguments.contains("SNAPSHOT_DEMO_MODE")
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isDemoMode)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isDemoMode || authManager.isAuthenticated {
                    OverView()
                        .environmentObject(authManager)
                        .environment(\.font, .custom("IBM Plex Sans", size: 17))
                        .preferredColorScheme(.dark)
                } else if isCheckingAuth {
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
                } else {
                    LoginViewOAuth()
                        .environmentObject(authManager)
                        .environment(\.font, .custom("IBM Plex Sans", size: 17))
                        .preferredColorScheme(.dark)
                        .background(Color.black.ignoresSafeArea())
                }
            }
            .onAppear {
                // Configure the API service with auth manager
                WatchTowerAPI.shared.configure(authManager: authManager)

                if ProcessInfo.processInfo.arguments.contains("SNAPSHOT_DEMO_MODE") {
                    seedDemoServers()
                    authManager.isAuthenticated = true
                    isCheckingAuth = false
                } else {
                    // Validate tokens on app startup
                    authManager.validateAndRefreshIfNeeded { success in
                        isCheckingAuth = false
                    }
                }
            }
            .onOpenURL { url in
                // OAuth callback handling
                print("Received URL: \(url)")
                // ASWebAuthenticationSession handles this automatically
            }
            .onChange(of: scenePhase) { _, newPhase in
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

    @MainActor
    private func seedDemoServers() {
        let context = sharedModelContainer.mainContext
        let demoServers: [(name: String, type: String, status: MachineStatus)] = [
            ("web-prod-01", "SERVER", .healthy),
            ("db-primary", "DATABASE", .warning),
            ("media-cdn", "SERVER", .offline),
        ]
        for demo in demoServers {
            let item = ServerModuleItem(machineUUID: UUID(), name: demo.name, type: demo.type)
            item.machineStatus = demo.status
            item.isConnected = demo.status != .offline
            item.lastConnected = demo.status != .offline ? Date() : nil
            context.insert(item)
        }
        try? context.save()
    }
}
