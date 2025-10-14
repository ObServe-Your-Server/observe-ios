//
//  ServerDetail.swift
//  ObServe
//
//  Created by Carlo Derouaux on 19.08.25.
//

import SwiftUI
import SwiftData

struct ServerDetailView: View {

    var server: ServerModuleItem
    
    @Environment(\.dismiss) private var dismiss
    @State private var contentHasScrolled = false
    @State private var selectedInterval: DetailAppBar.Interval = .s1
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                DetailAppBar(
                    serverName: server.name,
                    contentHasScrolled: $contentHasScrolled,
                    selectedInterval: $selectedInterval,
                    onClose: { dismiss() }
                )
                
                ScrollView {
                    scrollDetection
                    
                    VStack(spacing: 0) {
                        
                        // Server Management Module
                        ServerManagementModule(server: server)
                        
                        Rectangle().fill(.clear).frame(height: 12)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                }
                .coordinateSpace(name: "scroll")
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
        }
    }
    
    // MARK: - Scroll Detection
    var scrollDetection: some View {
        GeometryReader { proxy in
            let offset = proxy.frame(in: .named("scroll")).minY
            Color.clear.preference(key: ScrollPreferenceKey.self, value: offset)
        }
        .frame(height: 0)
        .onPreferenceChange(ScrollPreferenceKey.self) { value in
            withAnimation(.easeInOut(duration: 0.1)) {
                contentHasScrolled = value < -0.5
            }
        }
    }
    
    struct ScrollPreferenceKey: PreferenceKey {
        static var defaultValue: CGFloat = 0
        static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
            value = nextValue()
        }
    }
}

#Preview {
    ServerDetailView(server: ServerModuleItem(name: "Name filler", ip: "192.168.1.100", port: "8080", apiKey: "preview-key", type: "Server"))
}
