import XCTest

final class AppPreferencesUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    @MainActor private func start() -> XCUIApplication {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
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
    @MainActor func testNotificationToggleAndTimeEditorDoNotChangeExistingTasks() {
        let app = start()
        let toggle = app.switches["task-notifications-toggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5)); XCTAssertEqual(toggle.value as? String, "0")
        self.toggle("task-notifications-toggle", app); XCTAssertEqual(toggle.value as? String, "1")
        capture("30 Native task notification preferences", app)
        self.toggle("task-notifications-toggle", app); XCTAssertEqual(toggle.value as? String, "0")
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
        let app = start()
        toggle("task-notifications-toggle", app)
        XCTAssertEqual(app.switches["task-notifications-toggle"].value as? String, "0")
        XCTAssertTrue(app.buttons["Open iOS Settings"].exists)
        XCTAssertTrue(app.staticTexts["notification-preference-message"].waitForExistence(timeout: 5))
    }
    @MainActor func testPrivacyAndCareSourcesAreReachable() {
        let app = start()
        tap("preferences-data", app)
        XCTAssertTrue(app.navigationBars["Data & privacy"].exists)
        app.navigationBars["Data & privacy"].buttons.firstMatch.tap()
        tap("preferences-guidance", app)
        XCTAssertTrue(app.navigationBars["Care guidance & sources"].exists)
        app.navigationBars["Care guidance & sources"].buttons.firstMatch.tap()
        app.buttons["close-preferences"].tap(); app.buttons["home-add-plant"].tap()
        XCTAssertTrue(app.staticTexts["Choose a plant"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["select-species-Snake Plant"].exists)
    }
}
