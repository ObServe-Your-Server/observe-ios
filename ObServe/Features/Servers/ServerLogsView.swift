import SwiftUI

struct ServerLogsView: View {
    let server: ServerModuleItem

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var logsManager = ServerLogsManager.shared

    @State private var contentHasScrolled = false
    @State private var searchText = ""
    @State private var showExportSheet = false
    @State private var isLoading = false

    // MARK: - Computed

    private var allLogs: [ServerLogEntry] {
        logsManager.getLogs(for: server.id)
    }

    private var filteredLogs: [ServerLogEntry] {
        guard !searchText.isEmpty else { return allLogs }
        let query = searchText.lowercased()
        return allLogs.filter {
            $0.title.lowercased().contains(query) ||
                ($0.detail?.lowercased().contains(query) ?? false) ||
                $0.severity.rawValue.lowercased().contains(query)
        }
    }

    private var exportText: String {
        let header = "timestamp,severity,title,detail"
        let formatter = ISO8601DateFormatter()
        let rows = allLogs.map { entry -> String in
            let ts = formatter.string(from: entry.timestamp)
            let detail = (entry.detail ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let title = entry.title.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(ts)\",\"\(entry.severity.rawValue)\",\"\(title)\",\"\(detail)\""
        }
        return ([header] + rows).joined(separator: "\n")
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                AppBar(
                    title: "MACHINE LOGS",
                    contentHasScrolled: $contentHasScrolled,
                    onClose: { dismiss() },
                    secondaryImageName: "export",
                    secondaryLabel: "EXPORT",
                    secondaryAction: { showExportSheet = true }
                )

                if isLoading, allLogs.isEmpty {
                    Spacer()
                    ProgressView().tint(.white)
                    Spacer()
                } else if filteredLogs.isEmpty, searchText.isEmpty {
                    ScrollView {
                        ScrollDetector(contentHasScrolled: $contentHasScrolled)
                        searchBar
                        emptyState
                    }
                    .coordinateSpace(name: "scroll")
                    .refreshable { await refresh() }
                } else {
                    ScrollView {
                        ScrollDetector(contentHasScrolled: $contentHasScrolled)
                        searchBar
                        if filteredLogs.isEmpty {
                            emptyState
                        } else {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredLogs) { entry in
                                    LogEntryRow(entry: entry)
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
                    .refreshable { await refresh() }
                }
            }
        }
        .shareSheet(isPresented: $showExportSheet, text: exportText)
        .task { await refresh() }
    }

    // MARK: - Refresh

    private func refresh() async {
        isLoading = true
        await logsManager.fetchAndPersist(machineUUID: server.machineUUID, serverId: server.id)
        isLoading = false
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Color.white.opacity(0.4))
                .font(.plexSans(size: 16, weight: .medium))

            TextField("", text: $searchText, prompt: Text("SEARCH LOGS").foregroundColor(.white.opacity(0.4)))
                .foregroundStyle(Color.white)
                .font(.plexSans(size: 14))
                .tint(.white)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.plexSans(size: 14))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color("ButtonBackground"))
        .overlay(
            Rectangle()
                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
        )
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Text("NO LOGS")
                .font(.plexSans(size: 12, weight: .medium))
                .foregroundColor(Color.gray.opacity(0.5))
            Spacer()
        }
    }
}

// MARK: - Log Entry Row

private struct LogEntryRow: View {
    let entry: ServerLogEntry

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy HH:mm:ss"
        return f
    }()

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 6) {
                Text(Self.timestampFormatter.string(from: entry.timestamp))
                    .font(.plexSans(size: 11))
                    .foregroundColor(.gray)

                Text(entry.title)
                    .font(.plexSans(size: 14))
                    .foregroundColor(.white)
                    .fixedSize(horizontal: false, vertical: true)

                if let detail = entry.detail {
                    Text(detail)
                        .font(.plexSans(size: 12))
                        .foregroundColor(.gray)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.vertical, 12)

            Spacer()

            Rectangle()
                .fill(Color(entry.severity.colorName))
                .frame(width: 3, height: 20)
        }
    }
}

// MARK: - Share Sheet Helper

private extension View {
    func shareSheet(isPresented: Binding<Bool>, text: String) -> some View {
        sheet(isPresented: isPresented) {
            ActivityViewController(activityItems: [text])
                .ignoresSafeArea()
        }
    }
}

private struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}

// MARK: - Preview

#Preview {
    ServerLogsView(server: ServerModuleItem(machineUUID: UUID(), name: "Test Server", type: "Server"))
}
