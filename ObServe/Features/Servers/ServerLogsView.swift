import SwiftUI

struct ServerLogsView: View {

    let server: ServerModuleItem

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var logsManager = ServerLogsManager.shared

    @State private var contentHasScrolled = false
    @State private var searchText = ""
    @State private var showExportSheet = false

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
                    title: "SERVER LOGS",
                    contentHasScrolled: $contentHasScrolled,
                    onClose: { dismiss() },
                    secondaryIcon: "square.and.arrow.up",
                    secondaryLabel: "EXPORT",
                    secondaryAction: { showExportSheet = true }
                )

                searchBar

                if filteredLogs.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        ScrollDetector(contentHasScrolled: $contentHasScrolled)
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
                    .coordinateSpace(name: "scroll")
                }
            }
        }
        .shareSheet(isPresented: $showExportSheet, text: exportText)
    }

    // MARK: - Subviews

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 13))

            TextField("", text: $searchText)
                .foregroundColor(.white)
                .font(.system(size: 12))
                .overlay(alignment: .leading) {
                    if searchText.isEmpty {
                        Text("SEARCH LOGS")
                            .foregroundColor(Color.gray.opacity(0.6))
                            .font(.system(size: 12))
                            .allowsHitTesting(false)
                    }
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.system(size: 13))
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
                .font(.system(size: 12, weight: .medium))
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
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(Self.timestampFormatter.string(from: entry.timestamp))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray)

                Spacer()

                Text(entry.severity.rawValue)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(Color(entry.severity.colorName))
            }

            Text(entry.title)
                .font(.system(size: 14))
                .foregroundColor(.white)
                .fixedSize(horizontal: false, vertical: true)

            if let detail = entry.detail {
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Share Sheet Helper

private extension View {
    func shareSheet(isPresented: Binding<Bool>, text: String) -> some View {
        self.sheet(isPresented: isPresented) {
            ActivityViewController(activityItems: [text])
                .ignoresSafeArea()
        }
    }
}

private struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Preview

#Preview {
    ServerLogsView(server: ServerModuleItem(machineUUID: UUID(), name: "Test Server", type: "Server"))
}
