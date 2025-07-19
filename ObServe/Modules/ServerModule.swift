//
//  ServerModule.swift
//  ObServe
//
//  Created by Carlo Derouaux on 19.07.25.
//

import SwiftUI

struct ServerModule: View {
    var name: String = "SERVER NAME"
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
                .frame(height: 160)
                .padding(.vertical, 25)

            HStack {
                Text(name)
                    .foregroundColor(.white)
                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
                    .shadow(color: Color.green.opacity(1.2), radius: 10)
            }
            .padding(10)
            .background(Color.black)
            .offset(x: 10, y: 4)
        }
    }
}

#Preview {
    ServerModule()
        .background(Color.black)
}
