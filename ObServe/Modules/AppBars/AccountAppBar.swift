//
//  AccountAppBar.swift
//  ObServe
//
//  Created by Daniel Schatz on 21.11.25.
//

import SwiftUI

struct AccountAppBar: View {
    @Binding var contentHasScrolled: Bool
    @Binding var showBurgerMenu: Bool
    var usernameText: String = "User"

    var body: some View {
        BaseAppBar(
            title: "ACCOUNT",
            contentHasScrolled: $contentHasScrolled,
            rightButtonType: .hamburgerMenu,
            rightButtonAction: { showBurgerMenu = true }
        ) {
            Button(action: {
                // später später Link AppStore
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    Text(usernameText)
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
    ZStack {
        Color.black.ignoresSafeArea()
        AccountAppBar(
            contentHasScrolled: .constant(false),
            showBurgerMenu: .constant(false),
            usernameText: "Carlo"
        )
    }
}
