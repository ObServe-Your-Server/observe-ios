//
//  OverView.swift
//  ObServe
//
//  Created by Daniel Schatz on 16.07.25.
//

import SwiftUI
import SwiftData

struct OverView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAddServer = false
    @Query private var servers: [ServerModuleItem]

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                AppBar(machineCount: servers.count)
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(servers) { server in ServerModule(name: server.name)}
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)

                    // Add button
                    AddMachineButton {
                            showAddServer = true
                    }
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))

            // Overlay and AddServerView
            if showAddServer {
                AddServerOverlay(
                    onDismiss: { showAddServer = false },
                    onConnect: { newServer in
                        modelContext.insert(newServer)
                        try? modelContext.save()
                        showAddServer = false
                    }
                )
            }

        }
    }
}

#Preview {
    OverView()
}
