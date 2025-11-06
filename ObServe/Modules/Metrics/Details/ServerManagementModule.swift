//
//  ServerManagementModule.swift
//  ObServe
//
//  Created by GitHub Copilot on 22.09.25.
//

import SwiftUI

struct ServerManagementModule: View {
    @Bindable var server: ServerModuleItem
    var onManage: () -> Void

    @State private var osVersion = "Linux 6.8.12-15"
    @State private var status = ""

    // Blinking animation state
    @State private var isBlinking = false
    @State private var lightOpacity: Double = 1.0

    @StateObject private var metricsManager: MetricsManager

    init(server: ServerModuleItem, onManage: @escaping () -> Void) {
        self._server = Bindable(wrappedValue: server)
        self.onManage = onManage
        _metricsManager = StateObject(wrappedValue: MetricsManager(server: server))
        _status = State(initialValue: server.isHealthy ? "HEALTHY" : "UNHEALTHY")
    }

    /// Convert server type to proper image name
    private func getIconName(for serverType: String, isConnected: Bool) -> String {
        let suffix = isConnected ? "_on" : "_off"

        // Map server types to asset names
        switch serverType.uppercased() {
        case "SERVER":
            return "server" + suffix
        case "SINGLE BOARD":
            return "singleBoard" + suffix
        case "CUBE":
            return "cube" + suffix
        case "TOWER":
            return "tower" + suffix
        case "VM":
            return "vm" + suffix
        case "LAPTOP":
            return "laptop" + suffix
        default:
            return "server" + suffix // fallback
        }
    }

    /// Start blinking animation on icon tap
    private func startBlinking() {
        guard !isBlinking else { return }  // Prevent multiple simultaneous animations

        isBlinking = true
        lightOpacity = 1.0

        // Animate opacity with repeating fade in/out
        withAnimation(.easeInOut(duration: 0.4).repeatCount(6, autoreverses: true)) {
            lightOpacity = 0.0
        }

        // Reset state after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            isBlinking = false
            lightOpacity = 1.0
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                Spacer().frame(height: 5)
                
                // Server info and icon section
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 16) {
                        // Top row: UPTIME aligned with OS-VERSION
                        UpdateLabel(label: "UPTIME", value: metricsManager.uptime, showDaysInUptime: false)
                        UpdateLabel(
                            label: "STORAGE",
                            value: metricsManager.avgStorage,
                            max: metricsManager.maxStorage,
                            unit: "GB",
                            decimalPlaces: 2,
                            showPercent: true
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Server icon
                    VStack {
                        ZStack {
                            // Base layer: always show "off" state
                            Image(getIconName(for: server.type, isConnected: false))
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 96, maxHeight: 96)

                            // Overlay layer: "on" state with animated opacity
                            Image(getIconName(for: server.type, isConnected: true))
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 96, maxHeight: 96)
                                .opacity(isBlinking ? lightOpacity : (server.isConnected ? 1.0 : 0.0))
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .overlay(RoundedRectangle(cornerRadius: 0)
                        .stroke(Color(red: 0x47/255, green: 0x47/255, blue: 0x4A/255)))
                    .overlay(
                        FocusCorners(color: Color.white, size: 8, thickness: 1)
                    )
                    .onTapGesture {
                        startBlinking()
                        Haptics.click()
                    }
                }
                
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("OS VERSION")
                            .foregroundColor(Color.gray)
                            .font(.system(size: 12, weight: .medium))
                        Text(osVersion)
                            .foregroundColor(.white)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("STATUS")
                            .foregroundColor(Color.gray)
                            .font(.system(size: 12, weight: .medium))
                        Text(status)
                            .foregroundColor(.white)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
                // Action buttons - matching ServerModule styling
                HStack(spacing: 12) {
                    RegularButtonWhite(Label: "LOGS", action: {
                        // Schedule action
                    }, color: "ObServeGray")
                    .frame(maxWidth: .infinity)

                    BoldButtonWhite(Label: "MANAGE", action: {
                        onManage()
                    }, color: "ObServeGray")
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
                    showPercent: false,
                    serverId: server.id,
                    metricType: "CPU"
                )

                ExpandableMetricBox(
                    title: "RAM",
                    currentValue: metricsManager.maxRAM > 0 ? (metricsManager.avgRAM / metricsManager.maxRAM) * 100 : 0,
                    maximum: 100.0,
                    unit: "%",
                    decimalPlaces: 2,
                    showPercent: false,
                    serverId: server.id,
                    metricType: "RAM"
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
    ServerManagementModule(
        server: ServerModuleItem(name: "Test Server", ip: "192.168.1.100", port: "8080", apiKey: "preview-key", type: "Cube"),
        onManage: { print("Manage tapped") }
    )
    .background(Color.black)
}
