import SwiftUI

struct LiveMetricsView: View {
    @StateObject var fetcher = LiveMetricsFetcher(ip: "100.103.85.36", port: "8080")

    var body: some View {
        VStack {
            if let error = fetcher.error {
                Text("Error: \(error)").foregroundColor(.red)
            }

            List(fetcher.entries) { entry in
                HStack {
                    Text("\(Date(timeIntervalSince1970: entry.timestamp), style: .time)")
                    Spacer()
                    Text("\(entry.value * 100, specifier: "%.1f")%")
                }
            }

            Text("Updated: \(Date(), style: .time)")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.top)
        }
        .onAppear {
            fetcher.start()
        }
        .onDisappear {
            fetcher.stop()
        }
    }
}

struct LiveMetricsView_Previews: PreviewProvider {
    static var previews: some View {
        LiveMetricsView()
    }
}
