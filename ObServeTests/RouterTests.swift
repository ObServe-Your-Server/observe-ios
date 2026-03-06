//
//  RouterTests.swift
//  ObServeTests
//
//  Tests for Router navigation logic.
//

import Testing
@testable import ObServe

struct RouterTests {

    // MARK: - Initial State

    @Test func initialStateIsDashboard() {
        let router = Router()
        #expect(router.activePage == .dashboard)
    }

    // MARK: - navigate(to:)

    @Test func navigateToSettings() {
        let router = Router()
        router.navigate(to: .settings)
        #expect(router.activePage == .settings)
    }

    @Test func navigateToAccount() {
        let router = Router()
        router.navigate(to: .account)
        #expect(router.activePage == .account)
    }

    @Test func navigateToServer() {
        let router = Router()
        router.navigate(to: .server)
        #expect(router.activePage == .server)
    }

    @Test func navigateToAlerts() {
        let router = Router()
        router.navigate(to: .alerts)
        #expect(router.activePage == .alerts)
    }

    @Test func navigateToDashboard() {
        let router = Router()
        router.navigate(to: .settings)
        router.navigate(to: .dashboard)
        #expect(router.activePage == .dashboard)
    }

    @Test func navigateToLogoutDoesNotChangePage() {
        let router = Router()
        router.navigate(to: .settings)
        router.navigate(to: .logout)
        // logout is handled externally; activePage should remain unchanged
        #expect(router.activePage == .settings)
    }

    // MARK: - Multiple Navigations

    @Test func navigateMultipleTimes() {
        let router = Router()
        router.navigate(to: .settings)
        #expect(router.activePage == .settings)
        router.navigate(to: .account)
        #expect(router.activePage == .account)
        router.navigate(to: .dashboard)
        #expect(router.activePage == .dashboard)
    }

    // MARK: - Direct Assignment

    @Test func directPageAssignment() {
        let router = Router()
        router.activePage = .alerts
        #expect(router.activePage == .alerts)
        router.activePage = .dashboard
        #expect(router.activePage == .dashboard)
    }
}
