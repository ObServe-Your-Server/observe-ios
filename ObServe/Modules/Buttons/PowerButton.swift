//
//  PowerButton.swift
//  ObServe
//
//  Created by Carlo Derouaux on 19.07.25.
//

import SwiftUI

struct PowerButton: View {
    @Binding var isOn: Bool

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isOn.toggle()
                Haptics.click()
            }
        }) {
            ZStack {
                Text(isOn ? "SHUT DOWN" : "START UP")
                    .foregroundColor(Color(isOn ? "Red" : "Green"))
                    .font(.system(size: 12))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color(isOn ? "Red" : "Green").opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        FocusCorners(color: Color(isOn ? "Red" : "Green"), size: 8, thickness: 1)
                    )
                    .transition(.opacity)
            }
        }
    }
}


struct FocusCorners: View {
    let color: Color
    let size: CGFloat
    let thickness: CGFloat

    var body: some View {
        ZStack {
            ZStack(alignment: .topLeading) {
                color.frame(width: size, height: thickness)
                color.frame(width: thickness, height: size)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            ZStack(alignment: .topTrailing) {
                color.frame(width: size, height: thickness)
                color.frame(width: thickness, height: size)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

            ZStack(alignment: .bottomTrailing) {
                color.frame(width: thickness, height: size)
                color.frame(width: size, height: thickness)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            
            ZStack(alignment: .bottomLeading) {
                color.frame(width: thickness, height: size)
                color.frame(width: size, height: thickness)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
    }
}
