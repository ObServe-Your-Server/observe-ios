//
//  BurgerMenu.swift
//  ObServe
//
//  Created by Carlo Derouaux on 20.07.25.
//

import SwiftUI

enum MenuSection: String, CaseIterable {
    case dashboard = "DASHBOARD"
    case server = "SERVER"
    case alerts = "ALERTS"
    case account = "ACCOUNT"
    case settings = "SETTINGS"
    case logout = "LOGOUT"

    var iconOff: String {
        switch self {
        case .dashboard: return "dashboardIcon_off"
        case .server: return "serverIcon_off"
        case .alerts: return "alertsIcon_off"
        case .account: return "accountIcon_off"
        case .settings: return "settingsIcon_off"
        case .logout: return "logoutIcon_off"
        }
    }

    var iconOn: String {
        switch self {
        case .dashboard: return "dashboardIcon_on"
        case .server: return "serverIcon_on"
        case .alerts: return "alertsIcon_on"
        case .account: return "accountIcon_on"
        case .settings: return "settingsIcon_on"
        case .logout: return "logoutIcon_on"
        }
    }
}

struct BurgerMenu: View {
    var onDismiss: () -> Void
    var onDashboard: () -> Void
    var onServer: () -> Void
    var onAlerts: () -> Void
    var onAccount: () -> Void
    var onSettings: () -> Void
    var onLogout: () -> Void
    var selectedSection: MenuSection

    @State private var showPanel = false

    private let menuWidth: CGFloat = 240

    var body: some View {
        ZStack(alignment: .trailing) {

            Color.black
                .opacity(showPanel ? 0.6 : 0.0)
                .ignoresSafeArea()
                .onTapGesture { dismissAnimated() }
                .animation(.easeInOut(duration: 0.18), value: showPanel)


            VStack(spacing: 0) {
                // Header with app icon and version
                HStack(spacing: 12) {
                    Image("AppIcon")
                        .resizable()
                        .frame(width: 60, height: 60)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("ObServe")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                        Text("Version 1.0.0")
                            .font(.system(size: 12))
                            .foregroundColor(Color("ObServeGray"))
                    }

                    Spacer()
                }
                .padding(.horizontal, 30)
                .padding(.top, 20)
                .padding(.bottom, 30)

                // Menu items
                VStack(spacing: 10) {
                    ForEach(MenuSection.allCases, id: \.self) { section in
                        MenuItemView(
                            section: section,
                            isSelected: selectedSection == section,
                            action: {
                                dismissAnimated {
                                    handleSectionTap(section)
                                }
                            }
                        )
                    }
                }
                Spacer()
            }
            .frame(width: menuWidth)
            .frame(maxHeight: .infinity)
            .background(Color.black)
            .overlay(
                Rectangle()
                    .fill(Color("MenuAccentStroke"))
                    .frame(width: 1)
                    .frame(maxHeight: .infinity),
                alignment: .leading
            )
            .offset(x: showPanel ? 0 : menuWidth)
            .animation(.spring(response: 0.28, dampingFraction: 0.9), value: showPanel)
        }
        .onAppear {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.9)) {
                showPanel = true
            }
        }
    }

    // MARK: - Helpers
    private func dismissAnimated(after action: (() -> Void)? = nil) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.95)) {
            showPanel = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            onDismiss()
            action?()
        }
    }

    private func handleSectionTap(_ section: MenuSection) {
        switch section {
        case .dashboard: onDashboard()
        case .server: onServer()
        case .alerts: onAlerts()
        case .account: onAccount()
        case .settings: onSettings()
        case .logout: onLogout()
        }
    }
}

// MARK: - Menu Item View
struct MenuItemView: View {
    let section: MenuSection
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(isSelected ? section.iconOn : section.iconOff)
                    .resizable()
                    .renderingMode(.template)
                    .frame(width: 28, height: 28)
                    .foregroundColor(isSelected ? .white : Color("ObServeGray"))

                Text(section.rawValue)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : Color("ObServeGray"))

                Spacer()
            }
            .padding(.leading, 30)
            .padding(.vertical, 16)
            .background(
                HStack(spacing: 0) {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 0)
                            .fill(Color("MenuAccentStroke"))
                            .frame(width: 3)

                        Color("MenuSelectedBackground")
                    }
                }
                .offset(x: 15)
            )
        }
    }
}
