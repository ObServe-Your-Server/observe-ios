import SwiftUI

struct TestStorageView: View {
    @StateObject private var storageFetcher = LiveStorageFetcher(ip: "100.103.85.36", port: "8080", apiKey: "goofy-ass-key")
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Test Storage View")
                .font(.title)
                .padding(.top)
            if let error = storageFetcher.error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if let entry = storageFetcher.entries.last {
                Text("Latest Storage: \(String(format: "%.2f", entry.value)) GB")
                    .font(.headline)
            } else {
                Text("No storage data yet.")
            }
        }
        .onAppear {
            storageFetcher.start()
        }
        .onDisappear {
            storageFetcher.stop()
        }
        .padding()
    }
}

struct TestStorageView_Previews: PreviewProvider {
    static var previews: some View {
        TestStorageView()
            .padding()
            .background(Color(.systemBackground))
            .previewLayout(.sizeThatFits)
    }
}
