//
//  ServerDetail.swift
//  ObServe
//
//  Created by Carlo Derouaux on 19.08.25.
//

import SwiftUI
import SwiftData

struct ServerDetailView: View {

    var server: ServerModuleItem

    @Environment(\.dismiss) private var dismiss
    @State private var contentHasScrolled = false
    @State private var selectedInterval: AppBar.Interval = .s2
    @State private var showManageView = false
    @State private var showLogsView = false
    @StateObject private var metricsManager: MetricsManager

    init(server: ServerModuleItem) {
        self.server = server
        _metricsManager = StateObject(wrappedValue: MetricsManager(server: server))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                AppBar(
                    serverName: server.name,
                    contentHasScrolled: $contentHasScrolled,
                    selectedInterval: $selectedInterval,
                    onClose: { dismiss() }
                )
                
                ScrollView {
                    ScrollDetector(contentHasScrolled: $contentHasScrolled)
                    
                    VStack(spacing: 0) {
                        
                        Rectangle().frame(height: 8).opacity(0)

                        // Server Management Module
                        ServerManagementModule(
                            server: server,
                            metricsManager: metricsManager,
                            onLogs: { showLogsView = true },
                            onManage: { showManageView = true }
                        )

                        Rectangle().fill(.clear).frame(height: 12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                }
                .coordinateSpace(name: "scroll")
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
        .fullScreenCover(isPresented: $showLogsView) {
            ServerLogsView(server: server)
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
                }
            )
        }
        .onAppear {
            if server.isConnected {
                metricsManager.startFetching()
                metricsManager.setOverrideInterval(Int(selectedInterval.seconds))
                // Second fetch after 1s to get an initial network rate (needs two samples to compute delta)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    metricsManager.fetchLatestOnce()
                }
            }
        }
        .onChange(of: selectedInterval) { _, newValue in
            metricsManager.setOverrideInterval(Int(newValue.seconds))
        }
        .onDisappear {
            metricsManager.stopFetching()
        }
    }
    
}

#Preview {
    ServerDetailView(server: ServerModuleItem(machineUUID: UUID(), name: "Name filler", type: "Server"))
}
