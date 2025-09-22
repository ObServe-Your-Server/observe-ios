//
//  ServerManagementModule.swift
//  ObServe
//
//  Created by GitHub Copilot on 22.09.25.
//

import SwiftUI

struct ServerManagementModule: View {
    var server: ServerModuleItem?
    
    @State private var isOn = true
    // Convert running time to seconds for UPTIME formatting (120:56:12 = 120*3600 + 56*60 + 12)
    @State private var runtimeSeconds: Double = 435372 // 120:56:12 in seconds
    @State private var osVersion = "LX - 5.15"
    @State private var storageUsed = 1.26
    @State private var storageTotal = 2.0
    @State private var fansRPM: Double = 2300
    @State private var fansTotal = 5000.0
    
    @StateObject private var metricsManager: MetricsManager
    
    init(server: ServerModuleItem?) {
        self.server = server
        // Initialize MetricsManager with server or default values
        if let server = server {
            _metricsManager = StateObject(wrappedValue: MetricsManager(server: server))
        } else {
            // Create a default server for preview/testing
            let defaultServer = ServerModuleItem(name: "Default", ip: "192.168.1.100", port: "8080", type: "Server")
            _metricsManager = StateObject(wrappedValue: MetricsManager(server: defaultServer))
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                Spacer().frame(height: 5)
                
                // Server info and icon section
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Top row: UPTIME aligned with OS-VERSION
                        UpdateLabel(label: "UPTIME", value: runtimeSeconds)

                        // Bottom row: STORAGE aligned with FANS AVG
                        UpdateLabel(
                            label: "STORAGE",
                            value: storageUsed,
                            max: storageTotal,
                            unit: "TB",
                            decimalPlaces: 2,
                            showPercent: true
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    VStack(alignment: .leading, spacing: 16) {
                        // Top row: OS-VERSION aligned with UPTIME
                        VStack(alignment: .leading, spacing: 4) {
                            Text("OS-VERSION")
                                .foregroundColor(Color.gray)
                                .font(.system(size: 12, weight: .medium))
                            Text(osVersion)
                                .foregroundColor(.white)
                        }

                        // Bottom row: FANS aligned with STORAGE
                        UpdateLabel(
                            label: "FANS AVG",
                            value: 1,
                            max: 3,
                            unit: "RPM",
                            decimalPlaces: 0,
                            showPercent: true
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Server icon placeholder
                    VStack {
                        Image(systemName: "cube")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.8))

                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                // Action buttons - matching ServerModule styling
                HStack(spacing: 12) {
                    PowerButton(isOn: $isOn)
                        .frame(maxWidth: .infinity)
                    
                    RegularButton(Label: "SCHEDULE", action: {
                        // Schedule action
                    }, color: "Orange")
                    .frame(maxWidth: .infinity)
                    
                    CoolButton(
                        action: {
                            // Simulate a restart action
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            // Restart action
                        },
                        text: "RESTART",
                        color: "Blue"
                    )
                    .frame(maxWidth: .infinity)
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
                    Text(server?.type.uppercased() ?? "CUBE")
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(10)
                .background(Color.black)
                .padding(.top, -20)
                .padding(.leading, 10)
            }
            
            // Network metrics view below the server management module
            NetworkMetricsView(metricsManager: metricsManager)
            
            // CPU and RAM expandable metric boxes
            VStack(spacing: 20) {
                ExpandableMetricBox(
                    title: "CPU",
                    currentValue: metricsManager.avgCPU * 100,
                    maximum: 100.0,
                    unit: "%",
                    decimalPlaces: 2,
                    showPercent: false
                )

                ExpandableMetricBox(
                    title: "RAM",
                    currentValue: metricsManager.maxRAM > 0 ? (metricsManager.avgRAM / metricsManager.maxRAM) * 100 : 0,
                    maximum: 100.0,
                    unit: "%",
                    decimalPlaces: 2,
                    showPercent: false
                )
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
    ServerManagementModule(server: ServerModuleItem(name: "Test Server", ip: "192.168.1.100", port: "8080", type: "Cube"))
        .background(Color.black)
}
