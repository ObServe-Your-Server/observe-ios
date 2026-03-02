//
//  OverView.swift
//  ObServe
//
//  Created by Daniel Schatz on 16.07.25.
//

//
//  OverView.swift
//  ObServe
//

import SwiftUI
import SwiftData
import WidgetKit

struct OverView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAddServer = false
    @State private var showBurgermenu = false
    @Query private var servers: [ServerModuleItem]

    @State private var contentHasScrolled = false
    @State private var sortType: AppBar.SortType = .all

    @State private var selectedServer: ServerModuleItem?
    @State private var settingsRoute: SettingsRoute?
    @State private var accountRoute: AccountRoute?
    @State private var serverRoute: ServerRoute?
    @State private var alertsRoute: AlertsRoute?

    @EnvironmentObject var authManager: AuthenticationManager

    var filteredServers: [ServerModuleItem] {
        switch sortType {
        case .all:     return servers
        case .online:  return servers.filter { $0.isHealthy }
        case .offline: return servers.filter { !$0.isHealthy }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    AppBar(
                        machineCount: filteredServers.count,
                        contentHasScrolled: $contentHasScrolled,
                        showBurgerMenu: $showBurgermenu,
                        selectedSortType: $sortType
                    )

                    ScrollView {
                        scrollDetection
                        VStack(spacing: 0) {
                            if servers.isEmpty {
                                VStack(spacing: 0) {
                                    Rectangle().frame(height: 60).opacity(0)
                                    Image("NoMachines")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(.horizontal, 100)
                                    Rectangle()
                                        .fill(Color("ObServeGray"))
                                        .frame(width: 2, height: 200)
                                }
                            } else {
                                withAnimation {
                                    ForEach(filteredServers) { server in
                                        ServerModule(
                                            server: server,
                                            onDelete: {
                                                deleteServer(server)
                                            }
                                        )
                                        .contentShape(Rectangle())
                                        .onTapGesture { selectedServer = server }
                                    }
                                }
                            }

                            AddMachineButton {
                                withAnimation { showAddServer = true }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 20)
                    }
                    .coordinateSpace(name: "scroll")
                }
                .background(Color.black.ignoresSafeArea())
                .offset(x: showBurgermenu ? -240 : 0)
                .animation(.spring(response: 0.28, dampingFraction: 0.9), value: showBurgermenu)

                if showAddServer {
                    MachineOnboardingModal(
                        onDismiss: { withAnimation { showAddServer = false } },
                        onComplete: { newServer, machineType in
                            modelContext.insert(newServer)
                            try? modelContext.save()
                            syncServersToWidget()
                            withAnimation { showAddServer = false }
                        }
                    )
                    .zIndex(3)
                }

                if showBurgermenu {
                    BurgerMenu(
                        onDismiss: { showBurgermenu = false },
                        onDashboard: { showBurgermenu = false },
                        onServer: {
                            showBurgermenu = false
                            serverRoute = .init()
                        },
                        onAlerts: {
                            showBurgermenu = false
                            alertsRoute = .init()
                        },
                        onAccount: {
                            showBurgermenu = false
                            accountRoute = .init()
                        },
                        onSettings: {
                            showBurgermenu = false
                            settingsRoute = .init()
                        },
                        onLogout: {
                            showBurgermenu = false
                            authManager.logout()
                        },
                        selectedSection: .dashboard
                    )
                    .zIndex(4)
                }
            }
            .fullScreenCover(item: $selectedServer) { server in
                ServerDetailView(server: server)
                    .toolbar(.hidden, for: .navigationBar)
                    .background(Color.black.ignoresSafeArea())
            }
            .navigationDestination(item: $settingsRoute) { _ in
                SettingsOverview(
                    serverRoute: $serverRoute,
                    alertsRoute: $alertsRoute,
                    accountRoute: $accountRoute
                )
                .toolbar(.hidden, for: .navigationBar)
                .background(Color.black.ignoresSafeArea())
            }
            .navigationDestination(item: $accountRoute) { _ in
                AccountView(
                    serverRoute: $serverRoute,
                    alertsRoute: $alertsRoute,
                    settingsRoute: $settingsRoute
                )
                .toolbar(.hidden, for: .navigationBar)
                .background(Color.black.ignoresSafeArea())
            }
            .navigationDestination(item: $serverRoute) { _ in
                ServerView(
                    settingsRoute: $settingsRoute,
                    alertsRoute: $alertsRoute,
                    accountRoute: $accountRoute
                )
                .toolbar(.hidden, for: .navigationBar)
                .background(Color.black.ignoresSafeArea())
            }
            .navigationDestination(item: $alertsRoute) { _ in
                AlertsView(
                    settingsRoute: $settingsRoute,
                    serverRoute: $serverRoute,
                    accountRoute: $accountRoute
                )
                .toolbar(.hidden, for: .navigationBar)
                .background(Color.black.ignoresSafeArea())
            }
            .onAppear {
                syncMachinesFromBackend()
                syncServersToWidget()
            }
            .onChange(of: servers.count) { oldValue, newValue in
                syncServersToWidget()
            }
        }
    }

    // MARK: - Backend Sync

    private func syncMachinesFromBackend() {
        WatchTowerAPI.shared.fetchMachines { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let remoteMachines):
                    let existingUUIDs = Set(servers.compactMap { $0.machineUUID })

                    for remote in remoteMachines {
                        guard let uuid = UUID(uuidString: remote.uuid) else { continue }

                        if !existingUUIDs.contains(uuid) {
                            // New machine from backend — add locally
                            let newServer = ServerModuleItem(
                                machineUUID: uuid,
                                name: remote.name ?? "Unknown",
                                type: remote.type ?? "SERVER",
                                apiKey: remote.apiKey ?? ""
                            )
                            newServer.isConnected = true
                            newServer.isHealthy = true
                            modelContext.insert(newServer)
                        }
                    }

                    try? modelContext.save()
                    syncServersToWidget()

                case .failure(let error):
                    print("OverView: Failed to sync machines from backend: \(error.localizedDescription)")
                }
            }
        }
    }

    private func deleteServer(_ server: ServerModuleItem) {
        WatchTowerAPI.shared.deleteMachine(uuid: server.machineUUID) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    withAnimation {
                        modelContext.delete(server)
                        try? modelContext.save()
                        syncServersToWidget()
                    }
                case .failure(let error):
                    print("OverView: Failed to delete machine from backend: \(error.localizedDescription)")
                    // Still delete locally
                    withAnimation {
                        modelContext.delete(server)
                        try? modelContext.save()
                        syncServersToWidget()
                    }
                }
            }
        }
    }

    // MARK: - Widget Sync

    private func syncServersToWidget() {
        let sharedServers = servers.map { $0.toSharedServer() }
        SharedStorageManager.shared.saveServers(sharedServers)
        WidgetCenter.shared.reloadAllTimelines()
        print("OverView: Synced \(sharedServers.count) servers to widget")
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
    OverView()
}
