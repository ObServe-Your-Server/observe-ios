//
//  AboutAppBar.swift
//  ObServe
//
//  Created by Daniel Schatz
//

import SwiftUI

struct AboutAppBar: View {
    @Binding var contentHasScrolled: Bool
    var onClose: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("ABOUT ObServe")
                    .foregroundColor(.white)

                Button(action: {
                    if let url = URL(string: "https://observe.vision") {
                            UIApplication.shared.open(url)
                        }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                        Text("WEBSITE")
                            .font(.system(size: 11))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Color("ButtonBackground"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 0)
                            .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                    )
                }
            }

            Spacer()

            Button(action: onClose) {
                ZStack {
                    Image(systemName: "xmark")
                        .font(.system(size: 30, weight: .light))
                        .foregroundColor(.white)
                }
                .frame(width: 40, height: 40)
                .background(Color("ButtonBackground"))
                .overlay(
                    RoundedRectangle(cornerRadius: 0)
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(Color.black)
        .overlay(
            VStack(spacing: 0) {
                Spacer()
                if contentHasScrolled {
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 1)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: contentHasScrolled)
                }
            }
        )
    }
}

#Preview {
    AboutAppBar(
        contentHasScrolled: .constant(false),
        onClose: {}
    )
    .background(Color.black)
}
