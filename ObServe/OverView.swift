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

struct OverView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAddServer = false
    @State private var showBurgermenu = false
    @Query private var servers: [ServerModuleItem]

    @State private var contentHasScrolled = false
    @State private var sortType: AppBar.SortType = .all

    @State private var selectedServer: ServerModuleItem?
    @State private var settingsRoute: SettingsRoute?

    var filteredServers: [ServerModuleItem] {
        switch sortType {
        case .all:     return servers
        case .online:  return servers.filter { $0.isOn }
        case .offline: return servers.filter { !$0.isOn }
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

                if showAddServer {
                    AddServerOverlay(
                        onDismiss: { withAnimation { showAddServer = false } },
                        onConnect: { newServer in
                            modelContext.insert(newServer)
                            try? modelContext.save()
                            withAnimation { showAddServer = false }
                        }
                    )
                    .zIndex(3)
                }

                if showBurgermenu {
                    BurgerMenu(
                        onDismiss: { showBurgermenu = false },
                        onOverView: { showBurgermenu = false },
                        onSettings: {
                            showBurgermenu = false
                            settingsRoute = .init()
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
            .navigationDestination(item: $settingsRoute) { _ in
                SettingsOverview()
                    .toolbar(.hidden, for: .navigationBar)
                    .background(Color.black.ignoresSafeArea())
            }
        }
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

struct ScrollPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

#Preview {
    OverView()
}
