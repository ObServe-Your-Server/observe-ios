//
//  ServerView.swift
//  ObServe
//
//  Created by Daniel Schatz on 23.11.25.
//

import SwiftUI

struct ServerView: View {
    @State private var contentHasScrolled = false
    @State private var showBurgerMenu = false
    @EnvironmentObject var authManager: AuthenticationManager

    var router: Router

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // App bar später später
                HStack {
                    Text("SERVER")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

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
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showBurgerMenu = true
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
                    // später später
                    VStack(spacing: 20) {
                        Text("Server Management")
                            .font(.system(size: 16))
                            .foregroundColor(Color("ObServeGray"))
                            .padding(.top, 40)

                        Text("This view will contain server management features")
                            .font(.system(size: 14))
                            .foregroundColor(Color("ObServeGray").opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
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
                selectedSection: .dashboard,
                isOpen: $showBurgerMenu,
                onDashboard: { router.activePage = .dashboard },
                onLogout: {
                    showBurgerMenu = false
                    authManager.logout()
                }
            )
        }
        .background(Color.black)
        .toolbar(.hidden, for: .navigationBar)
    }
}
