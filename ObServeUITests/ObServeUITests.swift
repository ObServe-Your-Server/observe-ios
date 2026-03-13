//
//  ObServeUITests.swift
//  ObServeUITests
//

import XCTest

final class ObServeScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testTakeScreenshots() throws {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchArguments += ["SNAPSHOT_DEMO_MODE"]
        XCUIDevice.shared.orientation = .portrait
        app.launch()

        // Allow demo mode seeding and initial render to complete
        sleep(2)

        // MARK: - 01 Dashboard
        snapshot("01_Dashboard")

        // MARK: - 02 Settings
        openBurgerMenu(app)
        app.buttons["SETTINGS"].tap()
        sleep(1)
        snapshot("02_Settings")

        // MARK: - 03 Account
        openBurgerMenu(app)
        app.buttons["ACCOUNT"].tap()
        sleep(1)
        snapshot("03_Account")

        // MARK: - 04 Server detail
        // Navigate back to dashboard via burger menu
        openBurgerMenu(app)
        app.buttons["DASHBOARD"].tap()
        sleep(1)

        // Tap the DASHBOARD corner button on the first server card to open ServerDetailView
        app.buttons["DASHBOARD"].firstMatch.tap()
        sleep(2)
        snapshot("04_ServerDetail")

        // MARK: - 05 CPU metric expanded
        app.otherElements["expandableMetricBox_cpu"].tap()
        sleep(1)
        snapshot("05_CPUExpanded")
    }

    // MARK: - Helpers

    private func openBurgerMenu(_ app: XCUIApplication) {
        app.otherElements["burgerMenuButton"].tap()
        sleep(1)
    }
}
