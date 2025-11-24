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
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("ACCOUNT")
                    .foregroundColor(.white)

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
                    .frame(height: 1)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: contentHasScrolled)
            }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        AccountAppBar(contentHasScrolled: .constant(false),
                       showBurgerMenu: .constant(false),
                       usernameText: "Carlo")
    }
}
