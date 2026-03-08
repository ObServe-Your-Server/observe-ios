import SwiftUI

struct ServerModule: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var server: ServerModuleItem
    var onDelete: (() -> Void)?
    @State private var isConnected = false
    @State private var isHealthy = false
    @State private var isCheckingHealth = true
    @State private var showCheckingIndicator = false
    @State private var showManageView = false
    @State private var showDashboardView = false

    @StateObject private var metricsManager: MetricsManager
    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    init(server: ServerModuleItem, onDelete: (() -> Void)? = nil) {
        _server = Bindable(wrappedValue: server)
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
            if isCheckingHealth {
                showCheckingIndicator = true
            }
        }

        // Use the metrics/latest endpoint as a health check
        WatchTowerAPI.shared.fetchLatestMetric(machineUUID: server.machineUUID, timeoutInterval: 5) { result in
            DispatchQueue.main.async {
                let healthy = switch result {
                case .success:
                    true
                case .failure:
                    false
                }

                isHealthy = healthy
                server.isHealthy = healthy
                if healthy, isConnected {
                    server.lastConnected = Date()
                }
                isCheckingHealth = false
                showCheckingIndicator = false
                onComplete?()
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 12)

                if isConnected, isHealthy {
                    MetricsViewSimplified(metricsManager: metricsManager)
                } else {
                    HStack(spacing: 18) {
                        DateLabel(label: "LAST CONNECTED", date: lastConnectedString)
                        DateLabel(label: "STATUS", date: statusString)
                    }
                }

                HStack(spacing: 24) {
                    RegularButtonWhite(Label: "CONTROL", action: {}, color: "ObServeGray")
                        .frame(maxWidth: .infinity)
                        .disabled(isCheckingHealth)
                    CornerButton(label: "DASHBOARD", action: {
                        showDashboardView = true
                    })
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
                        .fill(Color(showCheckingIndicator ? "ObServeOrange" :
                                (isHealthy ? "ObServeGreen" : "ObServeRed")))
                        .frame(width: 10, height: 10)
                        .shadow(
                            color: Color(showCheckingIndicator ? "ObServeOrange" :
                                (isHealthy ? "ObServeGreen" : "ObServeRed")).opacity(3),
                            radius: 10
                        )
                }
                .padding(10)
                .background(Color.black)
                .padding(.top, -20)
                .padding(.leading, 10)
            }
        }
        .padding(.bottom, 20)
        .padding(.top, 10)
        .fullScreenCover(isPresented: $showDashboardView) {
            ServerDetailView(server: server)
                .toolbar(.hidden, for: .navigationBar)
                .background(Color.black.ignoresSafeArea())
        }
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

            if !isConnected {
                isConnected = true
            } else {
                metricsManager.startFetching()
            }
        }
        .onDisappear {
            metricsManager.stopFetching()
        }
        .onChange(of: isConnected) { _, newValue in
            server.isConnected = newValue
            if newValue {
                performHealthCheck {
                    if isHealthy {
                        metricsManager.startFetching()
                    } else {
                        isConnected = false
                        server.isConnected = false
                    }
                }
            } else {
                metricsManager.stopFetching()
            }
        }
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            if !isConnected, self.isConnected {
                self.isConnected = false
            } else if isConnected, server.isConnected {
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
