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
        BaseAppBar(
            title: "ABOUT ObServe",
            contentHasScrolled: $contentHasScrolled,
            rightButtonType: .close,
            rightButtonAction: onClose
        ) {
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
    }
}

#Preview {
    AboutAppBar(
        contentHasScrolled: .constant(false),
        onClose: {}
    )
    .background(Color.black)
}
