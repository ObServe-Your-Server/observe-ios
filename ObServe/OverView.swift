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
                                                withAnimation {
                                                    modelContext.delete(server)
                                                    try? modelContext.save()
                                                    syncServersToWidget()
                                                }
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
                syncServersToWidget()
            }
            .onChange(of: servers.count) { oldValue, newValue in
                syncServersToWidget()
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
            Color.clear.preference(key: ScrollPreferenceKey.self, value: offset)
        }
        .frame(height: 0)
        .onPreferenceChange(ScrollPreferenceKey.self) { value in
            withAnimation(.easeInOut(duration: 0.1)) {
                contentHasScrolled = value < -0.5
            }
        }
    }
}

struct SettingsRoute: Identifiable, Hashable {
    let id = UUID()
}

struct AccountRoute: Identifiable, Hashable {
    let id = UUID()
}

struct ServerRoute: Identifiable, Hashable {
    let id = UUID()
}

struct AlertsRoute: Identifiable, Hashable {
    let id = UUID()
}

struct ScrollPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

#Preview {
    OverView()
}
