//
//  AddMaschineKnopf.swift
//  ObServe
//
//  Created by Daniel Schatz on 19.07.25.
//

import SwiftUI

struct AddMachineButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("ADD MACHINE")
                .font(.system(size: 20, weight: .regular, design: .default))
                .foregroundColor(Color.gray.opacity(0.7))
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.7), Color.black]), startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.gray.opacity(0.4), lineWidth: 1)
                )
        }
        .frame(maxWidth: 200)
        .padding(.horizontal, 5)
        .padding(.bottom, 32)
    }
}
