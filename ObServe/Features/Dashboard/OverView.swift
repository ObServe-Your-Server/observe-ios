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
    @State private var router = Router()

    @EnvironmentObject var authManager: AuthenticationManager
    @State private var viewModel: OverViewModel?

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
                        ScrollDetector(contentHasScrolled: $contentHasScrolled)
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
                                                Task { await viewModel?.deleteServer(server, allServers: servers) }
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
                            viewModel?.syncServersToWidget(servers)
                            withAnimation { showAddServer = false }
                        }
                    )
                    .zIndex(3)
                }

                if showBurgermenu {
                    BurgerMenu(
                        router: router,
                        selectedSection: .dashboard,
                        onDismiss: { showBurgermenu = false },
                        onDashboard: { showBurgermenu = false },
                        onLogout: {
                            showBurgermenu = false
                            authManager.logout()
                        }
                    )
                    .zIndex(4)
                }
            }
            .fullScreenCover(item: $selectedServer) { server in
                ServerDetailView(server: server)
                    .toolbar(.hidden, for: .navigationBar)
                    .background(Color.black.ignoresSafeArea())
            }
            .navigationDestination(item: $router.settingsRoute) { _ in
                SettingsOverview(router: router)
                .toolbar(.hidden, for: .navigationBar)
                .background(Color.black.ignoresSafeArea())
            }
            .navigationDestination(item: $router.accountRoute) { _ in
                AccountView(router: router)
                .toolbar(.hidden, for: .navigationBar)
                .background(Color.black.ignoresSafeArea())
            }
            .navigationDestination(item: $router.serverRoute) { _ in
                ServerView(router: router)
                .toolbar(.hidden, for: .navigationBar)
                .background(Color.black.ignoresSafeArea())
            }
            .navigationDestination(item: $router.alertsRoute) { _ in
                AlertsView(router: router)
                .toolbar(.hidden, for: .navigationBar)
                .background(Color.black.ignoresSafeArea())
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = OverViewModel(modelContext: modelContext)
                }
                Task { await viewModel?.syncMachinesFromBackend(existingServers: servers) }
                viewModel?.syncServersToWidget(servers)
            }
            .onChange(of: servers.count) { oldValue, newValue in
                viewModel?.syncServersToWidget(servers)
            }
        }
    }

}


#Preview {
    OverView()
}
