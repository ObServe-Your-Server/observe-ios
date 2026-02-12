//
//  ResetAppBar.swift
//  ObServe
//
//  Created by Daniel Schatz
//

import SwiftUI

struct ResetAppBar: View {
    @Binding var contentHasScrolled: Bool
    let onClose: () -> Void

    var body: some View {
        BaseAppBar(
            title: "RESET DATA",
            contentHasScrolled: $contentHasScrolled,
            rightButtonType: .close,
            rightButtonAction: {
                Haptics.click()
                onClose()
            }
        ) {
            Button(action: {
                // später später
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    Text("U SURE?")
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
