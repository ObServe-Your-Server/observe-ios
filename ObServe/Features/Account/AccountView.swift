//
//  AccountView.swift
//  ObServe
//
//  Created by Daniel Schatz on 21.11.25.
//

import SwiftUI

struct AccountView: View {
    @State private var contentHasScrolled = false
    @State private var showBurgerMenu = false
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var authManager: AuthenticationManager

    var router: Router

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                AppBar(
                    title: "ACCOUNT",
                    contentHasScrolled: $contentHasScrolled,
                    showBurgerMenu: $showBurgerMenu,
                    secondaryIcon: "person.crop.circle",
                    secondaryLabel: "ACCOUNT"
                )

                ScrollView {
                    ScrollDetector(contentHasScrolled: $contentHasScrolled)

                    VStack(spacing: 35) {
                        VStack(alignment: .leading, spacing: 20) {
                            sectionHeader("MANAGE")
                            RegularButtonAccount(Label: "LOGOUT", action: { authManager.logout() }, color: "ObServeBlue")
                        }
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
            .background(Color.black.ignoresSafeArea())
            .overlay(
                Color.black
                    .opacity(showBurgerMenu ? 0.6 : 0.0)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            )
            .offset(x: showBurgerMenu ? -240 : 0)
            .animation(showBurgerMenu ? .spring(response: 0.28, dampingFraction: 0.9) : .spring(response: 0.2, dampingFraction: 0.95), value: showBurgerMenu)

            BurgerMenu(
                router: router,
                selectedSection: .account,
                isOpen: $showBurgerMenu,
                onDashboard: { dismiss() },
                onLogout: {
                    showBurgerMenu = false
                    authManager.logout()
                }
            )
        }
    }

    // MARK: - Helper Views
    @ViewBuilder
    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text)
                .foregroundColor(.white)
            Rectangle()
                .fill(Color.white.opacity(0.25))
                .frame(height: 1)
        }
    }
}

