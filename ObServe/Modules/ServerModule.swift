//
//  ServerModule.swift
//  ObServe
//
//  Created by Carlo Derouaux on 19.07.25.
//

import SwiftUI

struct ServerModule: View {
    var name: String = "SERVER NAME"
    var onDelete: (() -> Void)? = nil
    @State private var isOn = false

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 16) {
                Spacer().frame(height: 12)

                if isOn {
                    MetricsView()
                } else {
                    HStack(spacing: 16) {
                        DateLabel(label: "LAST RUNTIME", date: "20.05.25")
                        DateLabel(label: "RUNTIME DURATION", date: "204 : 22 : 10")
                    }
                }

                HStack(spacing: 12) {
                    PowerButton(isOn: $isOn)
                        .frame(maxWidth: .infinity)
                    RegularButton(Label: "SCHEDULE", color: "Orange")
                        .frame(maxWidth: .infinity)
                    
                    if !isOn {
                        RegularButton(Label: "MANAGE", action: {
                            onDelete?()
                        }, color: "Gray")
                        .frame(maxWidth: .infinity)
                    } else {
                        RegularButton(Label: "RESTART", action: {
                            onDelete?()
                        }, color: "Blue")
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
            .background(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.white.opacity(0.5), lineWidth: 1.5)
            )
            .overlay(alignment: .topLeading) {
                HStack {
                    Text(name)
                        .foregroundColor(.white)
                    Circle()
                        .fill(Color(isOn ? "Green" : "Red"))
                        .frame(width: 10, height: 10)
                        .shadow(color: Color(isOn ? "Green" : "Red").opacity(3), radius: 10)
                }
                .padding(10)
                .background(Color.black)
                .padding(.top, -20)
                .padding(.leading, 10)
            }
        }
        .padding(.vertical, 20)
    }
}

#Preview {
    ServerModule()
        .background(Color.black)
}
