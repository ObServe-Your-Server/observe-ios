//
//  ResetObServeView.swift
//  ObServe
//
//  Created by Daniel Schatz
//

import SwiftUI
import SwiftData

struct ResetObServeView: View {
    @State private var contentHasScrolled = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var servers: [ServerModuleItem] = []
    @State private var showClearMetricsConfirmation = false
    @State private var showClearWidgetDataConfirmation = false
    @State private var showRemoveServersConfirmation = false
    @State private var showResetSettingsConfirmation = false
    @State private var showResetAllConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            ResetAppBar(
                contentHasScrolled: $contentHasScrolled,
                onClose: { dismiss() }
            )

            ScrollView {
                scrollDetection

                VStack(spacing: 35) {
                    VStack(spacing: 10) {
                        // Clear Cached Metrics
                        sectionHeader("CLEAR CACHED METRICS")
                        
                        resetOption(
                            title: "Remove all stored metric history for all servers",
                            action: { showClearMetricsConfirmation = true }
                        )
                    }

                    VStack(spacing: 10) {
                        sectionHeader("CLEAR WIDGET DATA")
                        
                        resetOption(
                            title: "Remove all cached data from widgets",
                            action: { showClearWidgetDataConfirmation = true }
                        )
                    }
                    
                    VStack(spacing: 10) {
                        // Remove All Servers
                        sectionHeader("REMOVE ALL SERVERS")
                        
                        resetOption(
                            title: "Delete all configured servers (\(servers.count) servers)",
                            action: { showRemoveServersConfirmation = true },
                            disabled: servers.isEmpty
                        )
                    }
                    
                    VStack(spacing: 10) {
                        // Reset Settings
                        sectionHeader("RESET SETTINGS")
                        
                        resetOption(
                            title: "Restore all settings to default values",
                            action: { showResetSettingsConfirmation = true }
                        )
                    }
                    
                    VStack(spacing: 10) {
                        // Nuclear Option
                        sectionHeader("RESET EVERYTHING")
                        
                        resetOption(
                            title: "Clear all data, remove all servers, and reset settings",
                            action: { showResetAllConfirmation = true }
                        )
                    }

                    Rectangle().fill(.clear).frame(height: 12)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.top, 12)
            }
            .coordinateSpace(name: "scroll")
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            fetchServers()
        }
        .confirmationDialog("Clear Cached Metrics", isPresented: $showClearMetricsConfirmation, titleVisibility: .visible) {
            Button("Clear Metrics", role: .destructive) {
                clearCachedMetrics()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all stored metric history for all servers.")
        }
        .confirmationDialog("Clear Widget Data", isPresented: $showClearWidgetDataConfirmation, titleVisibility: .visible) {
            Button("Clear Widget Data", role: .destructive) {
                clearWidgetData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove all cached data from widgets.")
        }
        .confirmationDialog("Remove All Servers", isPresented: $showRemoveServersConfirmation, titleVisibility: .visible) {
            Button("Remove \(servers.count) Servers", role: .destructive) {
                removeAllServers()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all \(servers.count) configured servers.")
        }
        .confirmationDialog("Reset All Settings", isPresented: $showResetSettingsConfirmation, titleVisibility: .visible) {
            Button("Reset Settings", role: .destructive) {
                resetAllSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will restore all settings to their default values.")
        }
        .confirmationDialog("Reset Everything", isPresented: $showResetAllConfirmation, titleVisibility: .visible) {
            Button("Reset Everything", role: .destructive) {
                resetEverything()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will clear all data, remove all servers, and reset all settings. This action cannot be undone.")
        }
    }

    // MARK: - Data Fetching

    private func fetchServers() {
        let descriptor = FetchDescriptor<ServerModuleItem>()
        servers = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Reset Actions

    private func clearCachedMetrics() {
        SharedStorageManager.shared.clearAllMetrics()
        Haptics.notification(.success)
    }

    private func clearWidgetData() {
        SharedStorageManager.shared.clearAllMetrics()
        Haptics.notification(.success)
    }

    private func removeAllServers() {
        for server in servers {
            modelContext.delete(server)
        }
        try? modelContext.save()
        Haptics.notification(.success)
    }

    private func resetAllSettings() {
        SettingsManager.shared.resetAllSettings()
        Haptics.notification(.success)
    }

    private func resetEverything() {
        // Clear all data
        clearCachedMetrics()
        clearWidgetData()

        // Remove all servers
        removeAllServers()

        // Reset settings
        resetAllSettings()

        Haptics.notification(.success)
    }

    // MARK: - Scroll Detection
    private var scrollDetection: some View {
        GeometryReader { proxy in
            let offset = proxy.frame(in: .named("scroll")).minY
            Color.clear.preference(key: ResetScrollPreferenceKey.self, value: offset)
        }
        .frame(height: 0)
        .onPreferenceChange(ResetScrollPreferenceKey.self) { value in
            withAnimation(.easeInOut(duration: 0.12)) {
                contentHasScrolled = value < -0.5
            }
        }
    }

    // MARK: - UI Components

    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text)
                .foregroundColor(.white)
                .fixedSize(horizontal: true, vertical: false)
            Rectangle()
                .fill(Color.white.opacity(0.25))
                .frame(height: 1)
        }
    }

    @ViewBuilder
    private func resetOption(
        title: String,
        action: @escaping () -> Void,
        disabled: Bool = false
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title.uppercased())
                        .font(.system(size: 11))
                        .foregroundColor(disabled ? .gray : .gray)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .disabled(disabled)
    }
}

private struct ResetScrollPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

#Preview {
    ResetObServeView()
}
