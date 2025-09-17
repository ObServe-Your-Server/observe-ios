import SwiftUI

struct TestRamView: View {
    @StateObject private var ramFetcher = LiveRamFetcher(ip: "100.103.85.36", port: "8080")
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Test RAM View")
                .font(.title)
                .padding(.top)
            if let error = ramFetcher.error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if let entry = ramFetcher.entries.last {
                Text("Latest RAM: \(String(format: "%.2f", entry.value)) GB")
                    .font(.headline)
            } else {
                Text("No RAM data yet.")
            }
        }
        .onAppear {
            ramFetcher.start()
        }
        .onDisappear {
            ramFetcher.stop()
        }
        .padding()
    }
}

struct TestRamView_Previews: PreviewProvider {
    static var previews: some View {
        TestRamView()
            .padding()
            .background(Color(.systemBackground))
            .previewLayout(.sizeThatFits)
    }
}
