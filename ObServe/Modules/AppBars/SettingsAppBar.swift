//
//  SettingsAppBar.swift
//  ObServe
//
//  Created by Carlo Derouaux on 19.08.25.
//

import SwiftUI

struct SettingsAppBar: View {
    @Binding var contentHasScrolled: Bool
    @Binding var showBurgerMenu: Bool
    var versionText: String = "Version 1.0.0"

    var body: some View {
        BaseAppBar(
            title: "SETTINGS",
            contentHasScrolled: $contentHasScrolled,
            rightButtonType: .hamburgerMenu,
            rightButtonAction: { showBurgerMenu = true }
        ) {
            Button(action: {
                // später später Link AppStore
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                    Text(versionText)
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
        SettingsAppBar(
            contentHasScrolled: .constant(false),
            showBurgerMenu: .constant(false),
            versionText: "Version 1.0.0"
        )
    }
}
