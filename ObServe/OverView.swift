//
//  OverView.swift
//  ObServe
//
//  Created by Daniel Schatz on 16.07.25.
//

import SwiftUI

struct OverView: View {
    @State private var showAddServer = false
    @State private var servers: [ServerModuleItem] = []
        
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                AppBar(machineCount: servers.count)
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(servers) { server in ServerModule(name: server.name)}
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 10)
                    
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
                        servers.append(newServer)
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
