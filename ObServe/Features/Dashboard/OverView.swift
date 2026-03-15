import SwiftData
import SwiftUI
import WidgetKit

struct OverView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAddServer = false
    @State private var showBurgermenu = false
    @Query(sort: \ServerModuleItem.sortOrder) private var servers: [ServerModuleItem]

    @State private var contentHasScrolled = false
    @State private var sortType: AppBar.SortType = .all
    @State private var refreshTrigger: Int = 0

    // Drag-to-reorder float state (owned here so the card floats above AddMachineButton)
    @State private var draggingServer: ServerModuleItem? = nil
    @State private var floatOffsetY: CGFloat = 0

    @State private var router = Router()

    @EnvironmentObject var authManager: AuthenticationManager
    @State private var viewModel: OverViewModel?

    @ObservedObject private var networkMonitor = NetworkMonitor.shared

    private func networkBanner(label: String, color: String) -> some View {
        ZStack {
            Text(label)
                .foregroundColor(Color(color))
                .font(.plexSans(size: 12))
                .padding(.horizontal, 7)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
        }
        .innerShadow(
            color: Color(color),
            blur: 25,
            spread: 12,
            offsetX: 0,
            offsetY: 0,
            opacity: 0.1
        )
        .background(Color.black)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(color).opacity(0.5))
                .frame(height: 1)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color(color).opacity(0.5))
                .frame(height: 1)
        }
    }

    var filteredServers: [ServerModuleItem] {
        switch sortType {
        case .all: servers
        case .online: servers.filter(\.isHealthy)
        case .offline: servers.filter { !$0.isHealthy }
        }
    }

    var body: some View {
        ZStack {
            switch router.activePage {
            case .dashboard:
                dashboardPage
                    .transition(.opacity)
            case .settings:
                SettingsOverview(router: router)
                    .background(Color.black.ignoresSafeArea())
                    .transition(.opacity)
            case .account:
                AccountView(router: router)
                    .background(Color.black.ignoresSafeArea())
                    .transition(.opacity)
            case .server:
                ServerView(router: router)
                    .background(Color.black.ignoresSafeArea())
                    .transition(.opacity)
            case .alerts:
                AlertsView(router: router)
                    .background(Color.black.ignoresSafeArea())
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: router.activePage)
        .onAppear {
            if viewModel == nil {
                viewModel = OverViewModel(modelContext: modelContext)
            }
            Task { await viewModel?.syncMachinesFromBackend(existingServers: servers) }
            viewModel?.syncServersToWidget(servers)
        }
        .onChange(of: servers.count) { _, _ in
            viewModel?.syncServersToWidget(servers)
        }
    }

    private func reorderServers(from: Int, to: Int) {
        var ordered = servers
        let item = ordered.remove(at: from)
        let insertAt = min(to, ordered.count)
        ordered.insert(item, at: insertAt)
        for (newIndex, server) in ordered.enumerated() {
            server.sortOrder = newIndex
        }
        try? modelContext.save()
    }

    private var dashboardPage: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                AppBar(
                    machineCount: filteredServers.count,
                    contentHasScrolled: $contentHasScrolled,
                    showBurgerMenu: $showBurgermenu,
                    selectedSortType: $sortType
                )

                if !networkMonitor.isConnected {
                    networkBanner(label: "NO INTERNET CONNECTION", color: "ObServeRed")
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                } else if networkMonitor.showReconnectedBanner {
                    networkBanner(label: "INTERNET CONNECTED", color: "ObServeGreen")
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                }

                ScrollView {
                    ScrollDetector(contentHasScrolled: $contentHasScrolled)
                    ZStack(alignment: .top) {
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
                                ReorderableServerList(
                                    servers: filteredServers,
                                    refreshTrigger: refreshTrigger,
                                    onDelete: { server in
                                        Task { await viewModel?.deleteServer(server, allServers: servers) }
                                    },
                                    onReorder: sortType == .all ? { from, to in
                                        reorderServers(from: from, to: to)
                                    } : nil,
                                    draggingServer: $draggingServer,
                                    floatOffsetY: $floatOffsetY
                                )
                            }

                            AddMachineButton {
                                withAnimation { showAddServer = true }
                            }
                        }
                        .coordinateSpace(name: "reorderContainer")

                        // Floating dragged card — sits above AddMachineButton
                        if let server = draggingServer {
                            ServerModule(
                                server: server,
                                refreshTrigger: refreshTrigger,
                                onDelete: {}
                            )
                            .background(Color.black)
                            .scaleEffect(1.04)
                            .offset(y: floatOffsetY)
                            .allowsHitTesting(false)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                }
                .coordinateSpace(name: "scroll")
                .scrollDisabled(draggingServer != nil)
                .refreshable {
                    await viewModel?.syncMachinesFromBackend(existingServers: servers)
                    refreshTrigger += 1
                }
            }
            .background(Color.black.ignoresSafeArea())
            .overlay(
                Color.black
                    .opacity(showBurgermenu ? 0.6 : 0.0)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            )
            .offset(x: showBurgermenu ? -240 : 0)
            .animation(
                showBurgermenu ? .spring(response: 0.28, dampingFraction: 0.9) : .spring(
                    response: 0.2,
                    dampingFraction: 0.95
                ),
                value: showBurgermenu
            )
            .animation(.easeInOut(duration: 0.25), value: networkMonitor.isConnected)
            .animation(.easeInOut(duration: 0.25), value: networkMonitor.showReconnectedBanner)

            if showAddServer {
                MachineOnboardingModal(
                    onDismiss: { withAnimation { showAddServer = false } },
                    onComplete: { newServer, _ in
                        newServer.sortOrder = servers.count
                        modelContext.insert(newServer)
                        try? modelContext.save()
                        viewModel?.syncServersToWidget(servers)
                        withAnimation { showAddServer = false }
                    }
                )
                .zIndex(3)
            }

            BurgerMenu(
                router: router,
                selectedSection: .dashboard,
                isOpen: $showBurgermenu,
                onDashboard: { showBurgermenu = false },
                onLogout: {
                    showBurgermenu = false
                    authManager.logout()
                }
            )
            .zIndex(4)
        }
    }
}

#Preview {
    OverView()
}
