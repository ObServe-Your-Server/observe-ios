import SwiftUI

@Observable
final class Router {
    var activePage: ActivePage = .dashboard

    func navigate(to section: MenuSection) {
        switch section {
        case .dashboard:
            activePage = .dashboard
        case .alerts:
            activePage = .alerts
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
