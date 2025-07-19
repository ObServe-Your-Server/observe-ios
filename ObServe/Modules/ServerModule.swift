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
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(name)
                        .foregroundColor(.white)
                    Circle()
                        .fill(Color("ShutDown"))
                        .frame(width: 10, height: 10)
                        .shadow(color: Color("ShutDown").opacity(1.2), radius: 10)
                }
                .padding(10)
                .background(Color.black)
                .offset(x: 10, y: -20)

                VStack(alignment: .leading, spacing: 16) {
                    DateLabel(label: "LAST RUNTIME", date: "20.05.25")

                    HStack(spacing: 12) {
                        PowerButton()
                            .frame(maxWidth: .infinity)
                        RegularButton(Label: "SCHEDULE", color: "OnGoing")
                            .frame(maxWidth: .infinity)
                        RegularButton(Label: "MANAGE", color: "Gray")
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
            )
        }
        .padding(.vertical, 20)
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    ServerModule()
        .background(Color.black)
}
