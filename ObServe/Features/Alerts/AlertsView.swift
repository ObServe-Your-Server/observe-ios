import SwiftData
import SwiftUI

private enum AlertFilter: String, CaseIterable {
    case all = "ALL"
    case critical = "CRITICAL"
    case warning = "WARNING"
    case info = "INFO"
}

struct AlertsView: View {
    @State private var contentHasScrolled = false
    @State private var showBurgerMenu = false
    @State private var notifications: [MachineNotification] = []
    @State private var isLoading = false
    @State private var searchText = ""
    @State private var filter: AlertFilter = .all

    @Query(sort: \ServerModuleItem.sortOrder) private var servers: [ServerModuleItem]
    @EnvironmentObject var authManager: AuthenticationManager

    var router: Router

    private var filteredNotifications: [MachineNotification] {
        var result = notifications
        switch filter {
        case .all: break
        case .critical: result = result.filter { $0.severity == .critical }
        case .warning: result = result.filter { $0.severity == .warning }
        case .info: result = result.filter { $0.severity == .info }
        }
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                    ($0.description?.lowercased().contains(query) ?? false) ||
                    $0.severity.rawValue.lowercased().contains(query) ||
                    $0.machineName.lowercased().contains(query)
            }
        }
        return result
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                BaseAppBar(
                    title: "ALERTS",
                    contentHasScrolled: $contentHasScrolled,
                    rightButtonType: .hamburgerMenu,
                    rightButtonAction: { showBurgerMenu = true }
                ) {
                    Button {
                        let all = AlertFilter.allCases
                        if let i = all.firstIndex(of: filter) {
                            filter = all[(i + 1) % all.count]
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image("filter")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 11, height: 11)
                            Text("FILTER: \(filter.rawValue)")
                                .font(.plexSans(size: 11))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(Color("ButtonBackground"))
                        .overlay(
                            RoundedRectangle(cornerRadius: 0)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        )
                    }
                }

                if isLoading, notifications.isEmpty {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else if filteredNotifications.isEmpty, searchText.isEmpty, filter == .all {
                    ScrollView {
                        ScrollDetector(contentHasScrolled: $contentHasScrolled)
                        searchBar
                        emptyState
                    }
                    .coordinateSpace(name: "scroll")
                    .refreshable { await load() }
                } else {
                    ScrollView {
                        ScrollDetector(contentHasScrolled: $contentHasScrolled)
                        searchBar
                        if filteredNotifications.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredNotifications) { item in
                                    NotificationRow(item: item)
                                        .padding(.horizontal, 20)
                                    Rectangle()
                                        .fill(Color.white.opacity(0.08))
                                        .frame(height: 1)
                                        .padding(.leading, 20)
                                }
                            }
                            .padding(.bottom, 32)
                        }
                    }
                    .coordinateSpace(name: "scroll")
                    .refreshable { await load() }
                }
            }
            .overlay(
                Color.black
                    .opacity(showBurgerMenu ? 0.6 : 0.0)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            )
            .offset(x: showBurgerMenu ? -240 : 0)
            .animation(
                showBurgerMenu ? .spring(response: 0.28, dampingFraction: 0.9) : .spring(
                    response: 0.2,
                    dampingFraction: 0.95
                ),
                value: showBurgerMenu
            )

            BurgerMenu(
                router: router,
                selectedSection: .alerts,
                isOpen: $showBurgerMenu,
                onDashboard: { router.activePage = .dashboard },
                onLogout: {
                    showBurgerMenu = false
                    authManager.logout()
                }
            )
        }
        .background(Color.black)
        .toolbar(.hidden, for: .navigationBar)
        .task {
            loadPersisted()
            await load()
        }
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.white.opacity(0.4))
                .font(.plexSans(size: 16, weight: .medium))

            TextField("", text: $searchText, prompt: Text("SEARCH ALERTS").foregroundColor(.white.opacity(0.4)))
                .foregroundStyle(Color.white)
                .font(.plexSans(size: 14))
                .tint(.white)

            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.plexSans(size: 14))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color("ButtonBackground"))
        .overlay(Rectangle().stroke(Color.gray.opacity(0.5), lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text(servers.isEmpty ? "NO MACHINES" : "NO ALERTS")
                .font(.plexSans(size: 12, weight: .medium))
                .foregroundColor(Color.gray.opacity(0.5))
            Spacer()
        }
    }

    // MARK: - Load

    private func loadPersisted() {
        guard !servers.isEmpty else { return }
        let logsManager = ServerLogsManager.shared
        var results: [MachineNotification] = []
        for server in servers {
            let entries = logsManager.getLogs(for: server.id)
            let mapped = entries.map { MachineNotification(entry: $0, machineName: server.name) }
            results.append(contentsOf: mapped)
        }
        results.sort { $0.timestamp > $1.timestamp }
        if !results.isEmpty {
            notifications = results
        }
    }

    private func load() async {
        guard !servers.isEmpty else { return }
        isLoading = notifications.isEmpty

        var results: [MachineNotification] = []
        await withTaskGroup(of: [MachineNotification].self) { group in
            for server in servers {
                let uuid = server.machineUUID
                let name = server.name
                let serverId = server.id
                group.addTask {
                    await ServerLogsManager.shared.fetchAndPersist(machineUUID: uuid, serverId: serverId)
                    let entries = await ServerLogsManager.shared.getLogs(for: serverId)
                    return entries.map { MachineNotification(entry: $0, machineName: name) }
                }
            }
            for await batch in group {
                results.append(contentsOf: batch)
            }
        }
        results.sort { $0.timestamp > $1.timestamp }
        notifications = results
        isLoading = false
    }
}

// MARK: - Row

private struct NotificationRow: View {
    let item: MachineNotification

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy HH:mm:ss"
        return f
    }()

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Self.timestampFormatter.string(from: item.timestamp))
                    .font(.plexSans(size: 11))
                    .foregroundColor(.gray)

                Text("\(item.machineName) - \(item.title)")
                    .font(.plexSans(size: 14))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)

                if let desc = item.description {
                    Text(desc)
                        .font(.plexSans(size: 12))
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 12)

            Spacer()

            Rectangle()
                .fill(Color(item.severity.colorName))
                .frame(width: 3, height: 20)
        }
    }
}

// MARK: - Supporting types

private struct MachineNotification: Identifiable {
    let id: String
    let machineName: String
    let timestamp: Date
    let title: String
    let description: String?
    let severity: LogSeverity

    init(entry: ServerLogEntry, machineName: String) {
        id = entry.id.uuidString
        self.machineName = machineName
        timestamp = entry.timestamp
        title = entry.title
        description = entry.detail
        severity = entry.severity
    }
}
