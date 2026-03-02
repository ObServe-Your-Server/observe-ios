//
//  AlertsView.swift
//  ObServe
//
//  Created by Daniel Schatz on 23.11.25.
//

import SwiftUI

struct AlertsView: View {
    @State private var contentHasScrolled = false
    @State private var showBurgerMenu = false
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthenticationManager

    @Binding var settingsRoute: SettingsRoute?
    @Binding var serverRoute: ServerRoute?
    @Binding var accountRoute: AccountRoute?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // App bar später später
                HStack {
                    Text("ALERTS")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Button {
                        showBurgerMenu = true
                    } label: {
                        VStack(spacing: 7) {
                            Rectangle().fill(Color.gray).frame(width: 24, height: 2.5)
                            Rectangle().fill(Color.gray).frame(width: 24, height: 2.5)
                            Rectangle().fill(Color.gray).frame(width: 24, height: 2.5)
                        }
                        .padding(10)
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
                .padding(.bottom, 8)
                .background(Color.black)
                .overlay(
                    Rectangle()
                        .fill(contentHasScrolled ? Color.gray.opacity(0.3) : Color.clear)
                        .frame(height: 1),
                    alignment: .bottom
                )

                ScrollView {
                    //später später
                    VStack(spacing: 20) {
                        Text("Alerts & Notifications")
                            .font(.system(size: 16))
                            .foregroundColor(Color("ObServeGray"))
                            .padding(.top, 40)

                        Text("This view will contain alert and notification management features")
                            .font(.system(size: 14))
                            .foregroundColor(Color("ObServeGray").opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
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
                    onAlerts: { showBurgerMenu = false },
                    onAccount: {
                        showBurgerMenu = false
                        accountRoute = .init()
                    },
                    onSettings: {
                        showBurgerMenu = false
                        settingsRoute = .init()
                    },
                    onLogout: {
                        showBurgerMenu = false
                        authManager.logout()
                    },
                    selectedSection: .alerts
                )
            }
        }
        .background(Color.black)
        .toolbar(.hidden, for: .navigationBar)
    }
}
