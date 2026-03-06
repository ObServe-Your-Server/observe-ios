//
//  Router.swift
//  ObServe
//
//  Centralized navigation router. Drives top-level page switching
//  via a single activePage property — no NavigationStack push needed.
//

import SwiftUI

@Observable
final class Router {
    var activePage: ActivePage = .dashboard

    func navigate(to section: MenuSection) {
        switch section {
        case .dashboard:
            activePage = .dashboard
        //case .server:
        //    activePage = .server
        //case .alerts:
        //    activePage = .alerts
        case .account:
            activePage = .account
        case .settings:
            activePage = .settings
        case .logout:
            // Handled separately via AuthenticationManager
            break
        }
    }
}
