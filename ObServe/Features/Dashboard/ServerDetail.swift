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
                    scrollDetection
                    
                    VStack(spacing: 0) {
                        
                        Rectangle().frame(height: 20).opacity(0)

                        // Server Management Module
                        ServerManagementModule(
                            server: server,
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
    }
    
    // MARK: - Scroll Detection
    var scrollDetection: some View {
        GeometryReader { proxy in
            let offset = proxy.frame(in: .named("scroll")).minY
            Color.clear.preference(key: ScrollOffsetPreferenceKey.self, value: offset)
        }
        .frame(height: 0)
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            withAnimation(.easeInOut(duration: 0.12)) {
                contentHasScrolled = value < -0.5
            }
        }
    }
}

#Preview {
    ServerDetailView(server: ServerModuleItem(machineUUID: UUID(), name: "Name filler", type: "Server"))
}
