//
//  Switch.swift
//  ObServe
//
//  Created by Carlo Derouaux on 19.08.25.
//

import SwiftUI

struct Switch: View {
    @Binding var isOn: Bool

    private let switchWidth: CGFloat = 50
    private let trackHeight: CGFloat = 12
    private let thumbHeight: CGFloat = 32
    private let thumbWidth: CGFloat = 10
    private let innerBarWidth: CGFloat = 3
    private let innerBarHeight: CGFloat = 18

    private let edgeOverlap: CGFloat = 6

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.gray.opacity(0.65), lineWidth: 1.5)
                .frame(width: switchWidth, height: trackHeight)

            HStack {
                if isOn { Spacer() }
                thumb
                    .frame(width: thumbWidth, height: thumbHeight)
                    .padding(.leading, isOn ? 0 : -edgeOverlap)
                    .padding(.trailing, isOn ? -edgeOverlap : 0)
                    .zIndex(1)
                if !isOn { Spacer() }
            }
            .frame(width: switchWidth - 2, height: trackHeight)
        }
        .contentShape(Rectangle())
        .onTapGesture { toggleAnimated() }
    }

    // MARK: - Thumb
    private var thumb: some View {
        ZStack {
            Rectangle().fill(Color(white: 0.12))

            let glow = isOn ? Color("Green") : Color("Red")
            Rectangle()
                .fill(glow)
                .frame(width: innerBarWidth, height: innerBarHeight)
                .shadow(color: glow.opacity(0.4), radius: 8)
                .shadow(color: glow.opacity(0.7), radius: 14)
        }
        .overlay(
            Rectangle().stroke(Color.black.opacity(0.4), lineWidth: 0.5)
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: isOn)
    }

    private func toggleAnimated() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
            isOn.toggle()
            
            Haptics.click()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                Haptics.click()
            }
        }
    }
}
