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

    @EnvironmentObject private var authManager: AuthenticationManager
    @StateObject private var oauthManager = OAuthManager()

    @State private var userInfo: UserInfoResponse?
    @State private var isLoading = true
    @State private var loadError: String?

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

                        // MARK: - Profile Section
                        VStack(alignment: .leading, spacing: 20) {
                            sectionHeader("PROFILE")

                            if isLoading {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .tint(.white)
                                    Spacer()
                                }
                                .padding(.vertical, 12)
                            } else if let error = loadError {
                                Text(error.uppercased())
                                    .font(.system(size: 11))
                                    .foregroundColor(Color("ObServeRed"))
                            } else {
                                VStack(alignment: .leading, spacing: 16) {
                                    infoRow(
                                        label: "USERNAME",
                                        value: userInfo?.preferredUsername ?? "—"
                                    )
                                    infoRow(
                                        label: "EMAIL",
                                        value: userInfo?.email ?? "—"
                                    )
                                }
                            }
                        }

                        // MARK: - Manage Section
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader("MANAGE")

                            HStack(spacing: 12) {
                                RegularButtonAccount(
                                    Label: "CHANGE INFO",
                                    action: {
                                        oauthManager.openAuthentikFlow(
                                            urlString: OAuthConfiguration.userSettingsFlowURL
                                        )
                                    },
                                    color: "ObServeGray"
                                )

                                RegularButtonAccount(
                                    Label: "CHANGE PASSWORD",
                                    action: {
                                        oauthManager.openAuthentikFlow(
                                            urlString: OAuthConfiguration.passwordChangeFlowURL
                                        )
                                    },
                                    color: "ObServeGray"
                                )
                            }

                            RegularButtonAccount(
                                Label: "LOGOUT",
                                action: { authManager.logout() },
                                color: "ObServeBlue"
                            )
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
                onDashboard: { router.activePage = .dashboard },
                onLogout: {
                    showBurgerMenu = false
                    authManager.logout()
                }
            )
        }
        .onAppear {
            oauthManager.authenticationManager = authManager
            fetchUserInfo()
        }
    }

    // MARK: - Data Fetching

    private func fetchUserInfo() {
        isLoading = true
        loadError = nil
        WatchTowerAPI.shared.fetchUserInfo { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let info):
                    userInfo = info
                case .failure(let error):
                    loadError = error.localizedDescription
                }
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

    @ViewBuilder
    private func infoRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gray)
            Text(value.uppercased())
                .font(.system(size: 16))
                .foregroundColor(.white)
        }
    }

}
