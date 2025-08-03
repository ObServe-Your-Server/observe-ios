import SwiftUI

struct TestTotalRamView: View {
    @StateObject private var ramFetcher = LiveTotalRamFetcher(ip: "100.103.85.36", port: "8080")
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Test Total RAM View")
                .font(.title)
                .padding(.top)
            if let error = ramFetcher.error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if let maxRam = ramFetcher.maxRam {
                Text("Latest RAM: \(String(format: "%.2f", maxRam)) GB")
                    .font(.headline)
            } else {
                Text("No RAM data yet.")
            }
        }
        .onAppear {
            ramFetcher.fetchIfNeeded()
        }
        .padding()
    }
}

struct TestTotalRamView_Previews: PreviewProvider {
    static var previews: some View {
        TestTotalRamView()
            .padding()
            .background(Color(.systemBackground))
            .previewLayout(.sizeThatFits)
    }
}
