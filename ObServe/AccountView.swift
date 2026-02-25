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

    @Binding var serverRoute: ServerRoute?
    @Binding var alertsRoute: AlertsRoute?
    @Binding var settingsRoute: SettingsRoute?

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                AccountAppBar(
                    contentHasScrolled: $contentHasScrolled,
                    showBurgerMenu: $showBurgerMenu,
                    usernameText: "ACCOUNT"
                )

                ScrollView {
                    scrollDetection

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
            .offset(x: showBurgerMenu ? -240 : 0)
            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: showBurgerMenu)

            if showBurgerMenu {
                BurgerMenu(
                    onDismiss: { showBurgerMenu = false },
                    onDashboard: { dismiss() },
                    onServer: {
                        showBurgerMenu = false
                        serverRoute = .init()
                    },
                    onAlerts: {
                        showBurgerMenu = false
                        alertsRoute = .init()
                    },
                    onAccount: { showBurgerMenu = false },
                    onSettings: {
                        showBurgerMenu = false
                        settingsRoute = .init()
                    },
                    onLogout: {
                        showBurgerMenu = false
                        authManager.logout()
                    },
                    selectedSection: .account
                )
            }
        }
    }

    // MARK: - Scroll Detection
    private var scrollDetection: some View {
        GeometryReader { proxy in
            let offset = proxy.frame(in: .named("scroll")).minY
            Color.clear.preference(key: AccountScrollPreferenceKey.self, value: offset)
        }
        .frame(height: 0)
        .onPreferenceChange(AccountScrollPreferenceKey.self) { value in
            withAnimation(.easeInOut(duration: 0.12)) {
                contentHasScrolled = value < -0.5
            }
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

private struct AccountScrollPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}
