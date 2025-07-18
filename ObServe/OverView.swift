//
//  OverView.swift
//  ObServe
//
//  Created by Daniel Schatz on 16.07.25.
//

import SwiftUI

struct OverView: View {
    var body: some View {
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
    }
}

#Preview {
    OverView()
}
