import XCTest

final class AppPreferencesUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    @MainActor private func start(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--uitesting-preferences"] + extra; app.launch()
        app.buttons["home-preferences"].tap(); return app
    }
    @MainActor private func tap(_ id: String, _ app: XCUIApplication) {
        let button = app.buttons[id]
        for _ in 0..<5 { if button.isHittable { break }; app.swipeUp() }
        button.tap()
    }
    @MainActor private func toggle(_ id: String, _ app: XCUIApplication) {
        let row = app.switches[id]
        let control = row.switches.firstMatch
        if control.exists { control.tap() } else { row.tap() }
    }
    @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }
    @MainActor func testSharedProfileCanBeDisabledRestoredAndUsedBySearch() {
        let app = start()
        XCTAssertTrue(app.navigationBars["Preferences"].waitForExistence(timeout: 5))
        capture("29 Native app preferences", app)
        let picks = app.switches["preferences-personalized-picks"]
        toggle("preferences-personalized-picks", app); XCTAssertEqual(picks.value as? String, "0")
        app.buttons["close-preferences"].tap(); app.buttons["home-add-plant"].tap()
        XCTAssertTrue(app.staticTexts["Choose a plant"].waitForExistence(timeout: 5))
        app.navigationBars["Search plants"].buttons.firstMatch.tap(); app.buttons["home-preferences"].tap()
        toggle("preferences-personalized-picks", app); app.buttons["close-preferences"].tap(); app.buttons["home-add-plant"].tap()
        XCTAssertTrue(app.staticTexts["Seasonal picks"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Bushy · Trailing"].exists)
        app.buttons["personalize-plant-search"].tap()
        XCTAssertTrue(app.buttons["change-search-location"].exists)
        XCTAssertFalse(app.alerts.firstMatch.exists)
        XCTAssertTrue(app.staticTexts["Berlin"].exists)
    }
    @MainActor func testRemoveAreaUsesDraftSaveAndKeepsLightAndTypes() {
        let app = start(); app.buttons["preferences-growing-space"].tap()
        app.buttons["remove-search-area"].tap()
        XCTAssertTrue(app.textFields["search-growing-area"].exists)
        app.navigationBars["Your growing space"].buttons["Cancel"].tap()
        app.buttons["preferences-growing-space"].tap()
        XCTAssertTrue(app.staticTexts["Berlin"].exists)
        app.buttons["remove-search-area"].tap(); app.buttons["save-search-personalization"].tap()
        app.buttons["close-preferences"].tap(); app.buttons["home-add-plant"].tap()
        XCTAssertTrue(app.staticTexts["For your space"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Bushy · Trailing"].exists)
        app.buttons["personalize-plant-search"].tap()
        XCTAssertTrue(app.textFields["search-growing-area"].exists)
        XCTAssertEqual(app.buttons["search-light-Lower natural light"].value as? String, "Selected")
    }
    @MainActor func testNotificationToggleAndTimeEditorDoNotChangeExistingTasks() {
        let app = start(); tap("preferences-notifications", app)
        let toggle = app.switches["task-notifications-toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5)); XCTAssertEqual(toggle.value as? String, "0")
        self.toggle("task-notifications-toggle", app); XCTAssertEqual(toggle.value as? String, "1")
        capture("30 Native task notification preferences", app)
        self.toggle("task-notifications-toggle", app); XCTAssertEqual(toggle.value as? String, "0")
        app.navigationBars["Task notifications"].buttons.firstMatch.tap()
        tap("preferences-reminder-time", app)
        XCTAssertTrue(app.datePickers["default-reminder-time-picker"].exists)
        capture("31 Native default reminder time", app)
        app.navigationBars["Default reminder time"].buttons["Cancel"].tap()
        tap("preferences-reminder-time", app); app.buttons["save-default-reminder-time"].tap()
        app.buttons["close-preferences"].tap()
        XCTAssertTrue(app.staticTexts["My plants (5)"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Monstera")).firstMatch.exists)
    }
    @MainActor func testDeniedNotificationsKeepToggleOffAndShowRecovery() {
        let app = start(["--uitesting-notifications-denied"]); tap("preferences-notifications", app)
        toggle("task-notifications-toggle", app)
        XCTAssertEqual(app.switches["task-notifications-toggle"].value as? String, "0")
        XCTAssertTrue(app.buttons["Open iOS Settings"].exists)
        XCTAssertTrue(app.staticTexts["notification-preference-message"].waitForExistence(timeout: 5))
    }
    @MainActor func testLocationPrivacySourcesAndClearSearchesAreReachable() {
        let app = start(); tap("preferences-location", app)
        XCTAssertTrue(app.staticTexts["Berlin"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["preferences-change-area"].exists)
        capture("32 Native location access preferences", app)
        app.navigationBars["Location access"].buttons.firstMatch.tap()
        tap("preferences-clear-searches", app)
        app.buttons["Clear searches"].tap()
        capture("33 Native recent searches cleared", app)
        XCTAssertTrue(app.staticTexts["No recent searches"].waitForExistence(timeout: 5))
        tap("preferences-data", app)
        XCTAssertTrue(app.navigationBars["Data & privacy"].exists)
        app.navigationBars["Data & privacy"].buttons.firstMatch.tap()
        tap("preferences-guidance", app)
        XCTAssertTrue(app.navigationBars["Care guidance & sources"].exists)
        app.navigationBars["Care guidance & sources"].buttons.firstMatch.tap()
        app.buttons["close-preferences"].tap(); app.buttons["home-add-plant"].tap()
        XCTAssertFalse(app.buttons["recent-search-Monstera"].exists)
        XCTAssertTrue(app.staticTexts["Seasonal picks"].exists)
    }
}
