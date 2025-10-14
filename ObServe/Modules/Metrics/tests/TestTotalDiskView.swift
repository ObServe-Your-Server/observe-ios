import SwiftUI

struct TestTotalDiskView: View {
    @StateObject private var diskFetcher = LiveDiskTotalSizeFetcher(ip: "100.103.85.36", port: "8080", apiKey: "goofy-ass-key")
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Test Total Disk View")
                .font(.title)
                .padding(.top)
            if let error = diskFetcher.error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if let maxDisk = diskFetcher.maxDiskSize {
                Text("Latest Disk Size: \(String(format: "%.2f", maxDisk)) GB")
                    .font(.headline)
            } else {
                Text("No disk data yet.")
            }
        }
        .onAppear {
            diskFetcher.fetch()
        }
        .padding()
    }
}

struct TestTotalDiskView_Previews: PreviewProvider {
    static var previews: some View {
        TestTotalDiskView()
            .padding()
            .background(Color(.systemBackground))
            .previewLayout(.sizeThatFits)
    }
}
