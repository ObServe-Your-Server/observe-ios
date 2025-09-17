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
    @State private var isOn = false
    @State private var isCheckingHealth = true
    
    @StateObject private var metricsManager: MetricsManager
    private let networkService: NetworkService

    init(server: ServerModuleItem, onDelete: (() -> Void)? = nil) {
        self._server = Bindable(wrappedValue: server)
        self.onDelete = onDelete
        _metricsManager = StateObject(wrappedValue: MetricsManager(server: server))
        self.networkService = NetworkService(ip: server.ip, port: server.port)
    }

    private var lastRuntimeString: String {
        guard let lastRuntime = server.lastRuntime else {
            return "N/A"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter.string(from: lastRuntime)
    }
    
    private var runtimeDurationString: String {
        guard let duration = server.runtimeDuration else {
            return "00:00:00"
        }
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d : %02d : %02d", hours, minutes, seconds)
    }
    
    private func performHealthCheck() {
        print("Starting health check for server: \(server.name) at \(server.ip):\(server.port)")
        isCheckingHealth = true
        networkService.checkHealth { isHealthy in
            print("Health check result for \(self.server.name): \(isHealthy)")
            DispatchQueue.main.async {
                self.isOn = isHealthy
                self.server.isOn = isHealthy
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
                } else if isOn {
                    MetricsViewSimplified(metricsManager: metricsManager)
                } else {
                    HStack(spacing: 16) {
                        DateLabel(label: "LAST RUNTIME", date: lastRuntimeString) //should fetch from backend
                        DateLabel(label: "RUNTIME DURATION", date: runtimeDurationString) //should fetch from backend
                    }
                }

                HStack(spacing: 12) {
                    PowerButton(isOn: $isOn)
                        .frame(maxWidth: .infinity)
                        .disabled(isCheckingHealth)
                    RegularButton(Label: "SCHEDULE", color: "Orange")
                        .frame(maxWidth: .infinity)
                        .disabled(isCheckingHealth)
                    
                    if !isOn {
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
                        .fill(Color(isCheckingHealth ? "Orange" : (isOn ? "Green" : "Red")))
                        .frame(width: 10, height: 10)
                        .shadow(color: Color(isCheckingHealth ? "Orange" : (isOn ? "Green" : "Red")).opacity(3), radius: 10)
                }
                .padding(10)
                .background(Color.black)
                .padding(.top, -20)
                .padding(.leading, 10)
            }
        }
        .padding(.vertical, 20)
        .onAppear {
            performHealthCheck()
        }
        .onDisappear {
            metricsManager.stopFetching()
        }
        .onChange(of: isOn) { oldValue, newValue in
            if newValue {
                metricsManager.startFetching()
            } else {
                metricsManager.stopFetching()
            }
        }
    }
}

#Preview {
    let sampleServer = ServerModuleItem(name: "ObServe", ip: "100.103.85.36", port: "8080")
    ServerModule(server: sampleServer)
        .background(Color.black)
}
