//
//  Router.swift
//  ObServe
//
//  Centralized navigation router that owns all route state.
//  Replaces per-view @Binding route props and BurgerMenu closure soup.
//

import SwiftUI

@Observable
final class Router {
    var settingsRoute: SettingsRoute?
    var accountRoute: AccountRoute?
    var serverRoute: ServerRoute?
    var alertsRoute: AlertsRoute?

    func navigate(to section: MenuSection) {
        switch section {
        case .dashboard:
            // Handled by dismiss in each view
            break
        case .server:
            serverRoute = .init()
        case .alerts:
            alertsRoute = .init()
        case .account:
            accountRoute = .init()
        case .settings:
            settingsRoute = .init()
        case .logout:
            // Handled separately via AuthenticationManager
            break
        }
    }
}
