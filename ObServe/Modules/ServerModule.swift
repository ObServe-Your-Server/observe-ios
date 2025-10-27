//
//  ServerModule.swift
//  ObServe
//
//  Created by Carlo Derouaux on 19.07.25.
//

import SwiftUI

struct ServerModule: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var server: ServerModuleItem
    var onDelete: (() -> Void)? = nil
    @State private var isConnected = false
    @State private var isHealthy = false
    @State private var isCheckingHealth = true
    @State private var showCheckingIndicator = false
    @State private var showManageView = false

    @StateObject private var metricsManager: MetricsManager
    private let networkService: NetworkService

    init(server: ServerModuleItem, onDelete: (() -> Void)? = nil) {
        self._server = Bindable(wrappedValue: server)
        self.onDelete = onDelete
        _metricsManager = StateObject(wrappedValue: MetricsManager(server: server))
        self.networkService = NetworkService(ip: server.ip, port: server.port, apiKey: server.apiKey)
    }

    private var lastConnectedString: String {
        guard let lastConnected = server.lastConnected else {
            return "N/A"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: lastConnected)
    }

    private var statusString: String {
        if isCheckingHealth && showCheckingIndicator {
            return "connecting"
        }
        return isHealthy ? "online" : "offline"
    }
    
    private func performHealthCheck(onComplete: (() -> Void)? = nil) {
        print("Starting health check for server: \(server.name) at \(server.ip):\(server.port)")
        isCheckingHealth = true

        // Delay showing the orange indicator to prevent flickering
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if self.isCheckingHealth {
                self.showCheckingIndicator = true
            }
        }

        networkService.checkHealth { healthy in
            print("Health check result for \(self.server.name): \(healthy)")
            DispatchQueue.main.async {
                self.isHealthy = healthy
                self.server.isHealthy = healthy
                if healthy && self.isConnected {
                    self.server.lastConnected = Date()
                }
                self.isCheckingHealth = false
                self.showCheckingIndicator = false
                onComplete?()
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 12)

                if isConnected && isHealthy {
                    MetricsViewSimplified(metricsManager: metricsManager)
                } else {
                    HStack(spacing: 16) {
                        DateLabel(label: "LAST CONNECTED", date: lastConnectedString)
                        DateLabel(label: "STATUS", date: statusString)
                    }
                }

                HStack(spacing: 12) {
                    PowerButton(isConnected: $isConnected)
                        .frame(maxWidth: .infinity)
                        .disabled(isCheckingHealth)
                    if !isConnected {
                        RegularButton(Label: "MANAGE", action: {
                            showManageView = true
                        }, color: "ObServeGray")
                        .frame(maxWidth: .infinity)
                        .disabled(isCheckingHealth)
                    } else {
                        CoolButton(
                            action: {
                                // Simulate a restart action
                                try? await Task.sleep(nanoseconds: 2_000_000_000)
                            },
                            text: "RESTART",
                            color: "ObServeBlue"
                        )
                        .frame(maxWidth: .infinity)
                        .disabled(isCheckingHealth)
                    }
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
                    Text(server.name)
                        .foregroundColor(.white)
                    Circle()
                        .fill(Color(showCheckingIndicator ? "ObServeOrange" : (isHealthy ? "ObServeGreen" : "ObServeRed")))
                        .frame(width: 10, height: 10)
                        .shadow(color: Color(showCheckingIndicator ? "ObServeOrange" : (isHealthy ? "ObServeGreen" : "ObServeRed")).opacity(3), radius: 10)
                }
                .padding(10)
                .background(Color.black)
                .padding(.top, -20)
                .padding(.leading, 10)
            }
        }
        .padding(.vertical, 20)
        .sheet(isPresented: $showManageView) {
            ManageServerView(
                server: server,
                onDismiss: {
                    showManageView = false
                },
                onSave: { updatedServer in
                    // Update the server with new values
                    server.name = updatedServer.name
                    server.ip = updatedServer.ip
                    server.port = updatedServer.port
                    server.apiKey = updatedServer.apiKey
                    server.type = updatedServer.type

                    // If connection details changed, perform a new health check
                    performHealthCheck()
                },
                onDelete: onDelete
            )
        }
        .onAppear {
            isConnected = server.isConnected
            isHealthy = server.isHealthy
            performHealthCheck()
            if isConnected {
                metricsManager.startFetching()
            }
        }
        .onDisappear {
            metricsManager.stopFetching()
        }
        .onChange(of: isConnected) { oldValue, newValue in
            server.isConnected = newValue
            if newValue {
                // Perform health check before showing metrics
                performHealthCheck {
                    // Only start fetching metrics if health check passed
                    if self.isHealthy {
                        self.metricsManager.startFetching()
                    } else {
                        // If health check failed, disconnect automatically
                        self.isConnected = false
                        self.server.isConnected = false
                    }
                }
            } else {
                metricsManager.stopFetching()
            }
        }
    }
}

#Preview {
    let sampleServer = ServerModuleItem(name: "ObServe", ip: "100.109.12.45", port: "8080", apiKey: "preview-key", type: "Server")
    ServerModule(server: sampleServer)
        .background(Color.black)
}
