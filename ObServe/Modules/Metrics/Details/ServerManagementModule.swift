//
//  ServerManagementModule.swift
//  ObServe
//
//  Created by GitHub Copilot on 22.09.25.
//

import SwiftUI

struct ServerManagementModule: View {
    @Bindable var server: ServerModuleItem

    @State private var osVersion = "LX - 5.15"
    @State private var storageUsed = 1.26
    @State private var fansTotal = 5000.0

    @StateObject private var metricsManager: MetricsManager

    init(server: ServerModuleItem) {
        self._server = Bindable(wrappedValue: server)
        _metricsManager = StateObject(wrappedValue: MetricsManager(server: server))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                Spacer().frame(height: 5)
                
                // Server info and icon section
                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Top row: UPTIME aligned with OS-VERSION
                        UpdateLabel(label: "UPTIME", value: metricsManager.uptime, showDaysInUptime: false)
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
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Server icon
                    VStack {
                        let iconName = "\(server.type.lowercased())_\(server.isConnected ? "on" : "off")"
                        Image(iconName)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 96, maxHeight: 96)

                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                // Action buttons - matching ServerModule styling
                HStack(spacing: 12) {
                    PowerButton(isConnected: $server.isConnected)
                        .frame(maxWidth: .infinity)

                    RegularButton(Label: "SCHEDULE", action: {
                        // Schedule action
                    }, color: "ObServeOrange")
                    .frame(maxWidth: .infinity)

                    CoolButton(
                        action: {
                            // Simulate a restart action
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            // Restart action
                        },
                        text: "RESTART",
                        color: "ObServeBlue"
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
                    Text(server.type.uppercased())
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
        .onAppear {
            if server.isConnected {
                metricsManager.startFetching()
            }
        }
        .onDisappear {
            metricsManager.stopFetching()
        }
        .onChange(of: server.isConnected) { oldValue, newValue in
            if newValue {
                metricsManager.startFetching()
            } else {
                metricsManager.stopFetching()
            }
        }
    }
}

#Preview {
    ServerManagementModule(server: ServerModuleItem(name: "Test Server", ip: "192.168.1.100", port: "8080", apiKey: "preview-key", type: "Cube"))
        .background(Color.black)
}
