//
//  OverView.swift
//  ObServe
//
//  Created by Daniel Schatz on 16.07.25.
//

import SwiftUI

struct OverView: View {
    @State private var showAddServer = false
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            VStack(spacing: 0) {
                AppBar()
                ScrollView {
                    VStack(spacing: 20) {
                        ServerModule()
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                }
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            
            // Add button
            AddMachineButton {
                    showAddServer = true
            }

            // Overlay and AddServerView
            if showAddServer {
                AddServerOverlay {
                    showAddServer = false
                }
            }
            
        }
    }
}

#Preview {
    OverView()
}
