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
    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    init(server: ServerModuleItem, onDelete: (() -> Void)? = nil) {
        self._server = Bindable(wrappedValue: server)
        self.onDelete = onDelete
        _metricsManager = StateObject(wrappedValue: MetricsManager(server: server))
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
        isCheckingHealth = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if self.isCheckingHealth {
                self.showCheckingIndicator = true
            }
        }

        // Use the metrics/latest endpoint as a health check
        WatchTowerAPI.shared.fetchLatestMetric(machineUUID: server.machineUUID, timeoutInterval: 5) { result in
            DispatchQueue.main.async {
                let healthy: Bool
                switch result {
                case .success:
                    healthy = true
                case .failure:
                    healthy = false
                }

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
                    HStack(spacing: 18) {
                        DateLabel(label: "LAST CONNECTED", date: lastConnectedString)
                        DateLabel(label: "STATUS", date: statusString)
                    }
                }

                HStack(spacing: 18) {
                    PowerButton(isConnected: $isConnected)
                        .frame(maxWidth: .infinity)
                        .disabled(isCheckingHealth)
                    RegularButton(Label: "MANAGE", action: {
                        showManageView = true
                    }, color: "ObServeGray")
                    .frame(maxWidth: .infinity)
                    .disabled(isCheckingHealth)
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
        .padding(.bottom, 20)
        .padding(.top, 10)
        .fullScreenCover(isPresented: $showManageView) {
            ManageServerView(
                server: server,
                onDismiss: {
                    showManageView = false
                },
                onSave: { updatedServer in
                    server.name = updatedServer.name
                    server.type = updatedServer.type
                    performHealthCheck()
                },
                onDelete: onDelete
            )
        }
        .onAppear {
            isConnected = server.isConnected
            isHealthy = server.isHealthy
            metricsManager.onStatusChanged = { [self] newStatus in
                server.machineStatus = newStatus
                isHealthy = newStatus.isHealthy
            }
            performHealthCheck()

            if SettingsManager.shared.autoConnectOnLaunch && !isConnected {
                isConnected = true
            }

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
                performHealthCheck {
                    if self.isHealthy {
                        self.metricsManager.startFetching()
                    } else {
                        self.isConnected = false
                        self.server.isConnected = false
                    }
                }
            } else {
                metricsManager.stopFetching()
            }
        }
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            if !isConnected && self.isConnected {
                self.isConnected = false
            } else if isConnected && server.isConnected {
                self.isConnected = true
            }
        }
    }
}

#Preview {
    let sampleServer = ServerModuleItem(machineUUID: UUID(), name: "ObServe", type: "Server")
    ServerModule(server: sampleServer)
        .background(Color.black)
}
