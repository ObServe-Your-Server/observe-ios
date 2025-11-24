import SwiftUI

struct TestPingView: View {
    @StateObject private var pingFetcher = LivePingFetcher(ip: "100.103.85.36", port: "8080", apiKey: "goofy-ass-key")
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Test Ping View")
                .font(.title)
                .padding(.top)
            if let error = pingFetcher.error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if let entry = pingFetcher.entries.last {
                Text("Latest Ping: \(String(format: "%.1f", entry.value)) ms")
                    .font(.headline)
            } else {
                Text("No ping data yet.")
            }
        }
        .onAppear {
            pingFetcher.start()
        }
        .onDisappear {
            pingFetcher.stop()
        }
        .padding()
    }
}

struct TestPingView_Previews: PreviewProvider {
    static var previews: some View {
        TestPingView()
            .padding()
            .background(Color(.systemBackground))
            .previewLayout(.sizeThatFits)
    }
}
