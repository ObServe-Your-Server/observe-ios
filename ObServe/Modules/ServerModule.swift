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
        return isHealthy ? "online" : "offline"
    }
    
    private func performHealthCheck() {
        print("Starting health check for server: \(server.name) at \(server.ip):\(server.port)")
        isCheckingHealth = true
        networkService.checkHealth { healthy in
            print("Health check result for \(self.server.name): \(healthy)")
            DispatchQueue.main.async {
                self.isHealthy = healthy
                self.server.isHealthy = healthy
                if healthy && self.isConnected {
                    self.server.lastConnected = Date()
                }
                self.isCheckingHealth = false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 12)

                if isCheckingHealth {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Checking server status...")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
                } else if isConnected {
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
                            onDelete?()
                        }, color: "Gray")
                        .frame(maxWidth: .infinity)
                        .disabled(isCheckingHealth)
                    } else {
                        CoolButton(
                            action: {
                                // Simulate a restart action
                                try? await Task.sleep(nanoseconds: 2_000_000_000)
                                onDelete?()
                            },
                            text: "RESTART",
                            color: "Blue"
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
                        .fill(Color(isCheckingHealth ? "Orange" : (isHealthy ? "Green" : "Red")))
                        .frame(width: 10, height: 10)
                        .shadow(color: Color(isCheckingHealth ? "Orange" : (isHealthy ? "Green" : "Red")).opacity(3), radius: 10)
                }
                .padding(10)
                .background(Color.black)
                .padding(.top, -20)
                .padding(.leading, 10)
            }
        }
        .padding(.vertical, 20)
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
                metricsManager.startFetching()
                if isHealthy {
                    server.lastConnected = Date()
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
