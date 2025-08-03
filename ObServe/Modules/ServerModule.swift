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
    
    @StateObject private var metricsManager: MetricsManager

    init(server: ServerModuleItem, onDelete: (() -> Void)? = nil) {
        self._server = Bindable(wrappedValue: server)
        self.onDelete = onDelete
        _metricsManager = StateObject(wrappedValue: MetricsManager(server: server))
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
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 12)

                if isOn {
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
                    RegularButton(Label: "SCHEDULE", color: "Orange")
                        .frame(maxWidth: .infinity)
                    
                    if !isOn {
                        RegularButton(Label: "MANAGE", action: {
                            onDelete?()
                        }, color: "Gray")
                        .frame(maxWidth: .infinity)
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
                        .fill(Color(isOn ? "Green" : "Red"))
                        .frame(width: 10, height: 10)
                        .shadow(color: Color(isOn ? "Green" : "Red").opacity(3), radius: 10)
                }
                .padding(10)
                .background(Color.black)
                .padding(.top, -20)
                .padding(.leading, 10)
            }
        }
        .padding(.vertical, 20)
        .onAppear {
            if isOn {
                metricsManager.startFetching()
            }
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
    let sampleServer = ServerModuleItem(name: "Test Server", ip: "192.168.1.1", port: "8080")
    ServerModule(server: sampleServer)
        .background(Color.black)
}
