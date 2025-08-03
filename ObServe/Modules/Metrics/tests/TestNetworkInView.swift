import SwiftUI

struct TestNetworkInView: View {
    @StateObject private var networkInFetcher = LiveNetworkInFetcher(ip: "100.103.85.36", port: "8080")
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Test Network In View")
                .font(.title)
                .padding(.top)
            if let error = networkInFetcher.error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if let entry = networkInFetcher.entries.last {
                Text("Latest Network In: \(String(format: "%.2f", entry.value)) kB/s")
                    .font(.headline)
            } else {
                Text("No Network In data yet.")
            }
        }
        .onAppear {
            networkInFetcher.start()
        }
        .onDisappear {
            networkInFetcher.stop()
        }
        .padding()
    }
}

struct TestNetworkInView_Previews: PreviewProvider {
    static var previews: some View {
        TestNetworkInView()
            .padding()
            .background(Color(.systemBackground))
            .previewLayout(.sizeThatFits)
    }
}
