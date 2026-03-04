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
    @State private var selectedInterval: AppBar.Interval = .s1
    @State private var showManageView = false
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
                // Second fetch after 1s to get an initial network rate (needs two samples to compute delta)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    metricsManager.fetchLatestOnce()
                }
            }
        }
        .onDisappear {
            metricsManager.stopFetching()
        }
    }
    
}

#Preview {
    ServerDetailView(server: ServerModuleItem(machineUUID: UUID(), name: "Name filler", type: "Server"))
}
