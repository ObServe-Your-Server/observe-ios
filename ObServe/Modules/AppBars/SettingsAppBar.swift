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
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("SETTINGS")
                    .foregroundColor(.white)

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

            Spacer()

            Button {
                showBurgerMenu = true
            } label: {
                VStack(spacing: 7) {
                    Rectangle().fill(Color.gray).frame(width: 24, height: 2.5)
                    Rectangle().fill(Color.gray).frame(width: 24, height: 2.5)
                    Rectangle().fill(Color.gray).frame(width: 24, height: 2.5)
                }
                .padding(8)
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
        .overlay(alignment: .bottom) {
            if contentHasScrolled {
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 2)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: contentHasScrolled)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SettingsAppBar(contentHasScrolled: .constant(false),
                       showBurgerMenu: .constant(false),
                       versionText: "Version 1.0.0")
    }
}
