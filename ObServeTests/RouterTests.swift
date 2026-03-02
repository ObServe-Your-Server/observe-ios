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

    @Test func initialStateIsAllNil() {
        let router = Router()
        #expect(router.settingsRoute == nil)
        #expect(router.accountRoute == nil)
        #expect(router.serverRoute == nil)
        #expect(router.alertsRoute == nil)
    }

    // MARK: - navigate(to:)

    @Test func navigateToSettings() {
        let router = Router()
        router.navigate(to: .settings)
        #expect(router.settingsRoute != nil)
        #expect(router.accountRoute == nil)
        #expect(router.serverRoute == nil)
        #expect(router.alertsRoute == nil)
    }

    @Test func navigateToAccount() {
        let router = Router()
        router.navigate(to: .account)
        #expect(router.accountRoute != nil)
        #expect(router.settingsRoute == nil)
        #expect(router.serverRoute == nil)
        #expect(router.alertsRoute == nil)
    }

    @Test func navigateToServer() {
        let router = Router()
        router.navigate(to: .server)
        #expect(router.serverRoute != nil)
        #expect(router.settingsRoute == nil)
        #expect(router.accountRoute == nil)
        #expect(router.alertsRoute == nil)
    }

    @Test func navigateToAlerts() {
        let router = Router()
        router.navigate(to: .alerts)
        #expect(router.alertsRoute != nil)
        #expect(router.settingsRoute == nil)
        #expect(router.accountRoute == nil)
        #expect(router.serverRoute == nil)
    }

    @Test func navigateToDashboardDoesNothing() {
        let router = Router()
        router.navigate(to: .dashboard)
        #expect(router.settingsRoute == nil)
        #expect(router.accountRoute == nil)
        #expect(router.serverRoute == nil)
        #expect(router.alertsRoute == nil)
    }

    @Test func navigateToLogoutDoesNothing() {
        let router = Router()
        router.navigate(to: .logout)
        #expect(router.settingsRoute == nil)
        #expect(router.accountRoute == nil)
        #expect(router.serverRoute == nil)
        #expect(router.alertsRoute == nil)
    }

    // MARK: - Multiple Navigations

    @Test func navigateToMultipleSections() {
        let router = Router()
        router.navigate(to: .settings)
        router.navigate(to: .account)
        // Both should be set (NavigationStack handles which is presented)
        #expect(router.settingsRoute != nil)
        #expect(router.accountRoute != nil)
    }

    // MARK: - Route Clearing

    @Test func clearingRouteManually() {
        let router = Router()
        router.navigate(to: .settings)
        #expect(router.settingsRoute != nil)

        router.settingsRoute = nil
        #expect(router.settingsRoute == nil)
    }
}
