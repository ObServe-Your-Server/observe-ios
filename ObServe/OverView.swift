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
    @State private var sortType: AppBar.SortType = .all
    
    var filteredServers: [ServerModuleItem] {
        switch sortType {
            case .all:
                return servers
            case .online:
                return servers.filter { $0.isOn }
            case .offline:
                return servers.filter { !$0.isOn }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                AppBar(machineCount: filteredServers.count, selectedSortType: $sortType)
                ScrollView {
                    VStack(spacing: 0) {
                        if servers.isEmpty {
                            VStack(spacing: 0) {
                                Rectangle()
                                    .frame(height: 60)
                                    .opacity(0)
                                Image("NoMachines")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(.horizontal, 100)

                                Rectangle()
                                    .fill(Color("Gray"))
                                    .frame(width: 2, height: 200)
                            }
                        } else {
                            withAnimation {
                                ForEach(filteredServers) { server in
                                    ServerModule(
                                        server: server,
                                        onDelete: {
                                            withAnimation {
                                                modelContext.delete(server)
                                                try? modelContext.save()
                                            }
                                        }
                                    )
                                }
                            }
                        }

                        AddMachineButton {
                            withAnimation {
                                showAddServer = true
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))

            if showAddServer {
                AddServerOverlay(
                    onDismiss: { withAnimation { showAddServer = false } },
                    onConnect: { newServer in
                        modelContext.insert(newServer)
                        try? modelContext.save()
                        withAnimation {
                            showAddServer = false
                        }
                    }
                )
            }

        }
    }
}

#Preview {
    OverView()
}
