//
//  OverView.swift
//  ObServe
//
//  Created by Daniel Schatz on 16.07.25.
//

import SwiftUI
import SwiftData

struct OverView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var showAddServer = false
    @State private var showBurgermenu = false
    @Query private var servers: [ServerModuleItem]
    
    @State private var contentHasScrolled = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                AppBar(machineCount: servers.count, contentHasScrolled: $contentHasScrolled, showBurgerMenu: $showBurgermenu)
                ScrollView {
                    scrollDetection
                    VStack(spacing: 0) {
                        if servers.isEmpty {
                            VStack(spacing: 0) {
                                Rectangle()
                                    .frame(height: 60)
                                    .opacity(0)
                                Image("NoMachines")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(.horizontal, 100)
                                
                                Rectangle()
                                    .fill(Color("Gray"))
                                    .frame(width: 2, height: 200)
                            }
                        } else {
                            ForEach(servers) { server in
                                ServerModule(
                                    name: server.name,
                                    onDelete: {
                                        modelContext.delete(server)
                                        try? modelContext.save()
                                    }
                                )
                            }
                        }
                        
                        AddMachineButton {
                            showAddServer = true
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            
            if showAddServer {
                AddServerOverlay(
                    onDismiss: { showAddServer = false },
                    onConnect: { newServer in
                        modelContext.insert(newServer)
                        try? modelContext.save()
                        showAddServer = false
                    }
                )
            }
            if showBurgermenu {
                BurgerMenu(onDismiss: { showBurgermenu = false })
            }
        }
    }
    
    var scrollDetection: some View {
        GeometryReader { proxy in
            let offset = proxy.frame(in: .named("scroll")).minY
            Color.clear
                .preference(key: ScrollPreferenceKey.self, value: offset)
        }
        .frame(height: 0)
        .onPreferenceChange(ScrollPreferenceKey.self) { value in
            withAnimation(.easeInOut(duration: 0.1)) {
                contentHasScrolled = value < 100
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
    OverView()
}
