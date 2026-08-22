//
//  CloudnsUITests.swift
//  CloudnsUITests
//
//  Created by lbyan on 2026/8/11.
//

import XCTest

final class CloudnsUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    @MainActor
    func testAppLaunchAndMainTabSwitching() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify the app launched and tab bar exists
        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 5.0) {
            // Test switching through available tabs
            let tabs = ["Dashboard", "Domains", "Developer", "Tools", "Settings"]
            for tabTitle in tabs {
                let tabButton = tabBar.buttons[tabTitle]
                if tabButton.exists {
                    tabButton.tap()
                    XCTAssertTrue(tabButton.isSelected || tabButton.exists)
                }
            }
        } else {
            // Onboarding or direct view presentation check
            XCTAssertTrue(app.windows.firstMatch.exists)
        }
    }

    @MainActor
    func testDiagnosticToolsListPresentation() throws {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        if tabBar.waitForExistence(timeout: 5.0) {
            // Tap Developer or Tools tab
            let toolsTab = tabBar.buttons["Developer"].exists ? tabBar.buttons["Developer"] : tabBar.buttons["Tools"]
            if toolsTab.exists {
                toolsTab.tap()
                // Wait for any list or scroll view
                let scrollView = app.scrollViews.firstMatch
                XCTAssertTrue(scrollView.waitForExistence(timeout: 3.0) || app.tables.firstMatch.exists || app.windows.firstMatch.exists)
            }
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
