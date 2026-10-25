import XCTest

@MainActor final class AuditUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private func launch() -> XCUIApplication {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch(); return app
    }
    private func capture(_ name: String, _ app: XCUIApplication) {
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }
    private func tap(_ id: String, _ app: XCUIApplication) {
        let element = app.buttons[id]
        for _ in 0..<6 { if element.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(element.waitForExistence(timeout: 5)); element.tap()
    }
    private func dismissFeedback(_ app: XCUIApplication) {
        if app.buttons["dismiss-care-feedback"].exists { app.buttons["dismiss-care-feedback"].tap() }
    }
    private func newInspection(_ app: XCUIApplication) {
        tap("plant-Snake Plant", app); tap("start-observation", app)
        capture("Audit observation areas", app)
        tap("observation-area-leaves", app); tap("Dropping leaves", app)
        tap("continue-observation", app); tap("save-change", app)
        XCTAssertTrue(app.buttons["leaf-start-care-plan"].waitForExistence(timeout: 5))
        capture("Audit possible causes", app)
        XCTAssertFalse(app.switches["leaf-follow-up-toggle"].exists)
        tap("leaf-start-care-plan", app); dismissFeedback(app)
    }
    private func completeInspection(_ app: XCUIApplication) {
        for _ in 0..<3 {
            tap("plant-next-care-task", app); tap("finish-plan-task", app)
            if app.buttons["skip-completion-check-in"].waitForExistence(timeout: 1) { return }
            dismissFeedback(app)
        }
    }
    func testInlinePreferencesAndPhotoEditingPreservePlantIdentity() {
        let app = launch(); capture("Audit home", app)
        tap("home-preferences", app)
        XCTAssertTrue(app.switches["task-notifications-toggle"].exists)
        XCTAssertFalse(app.buttons["preferences-notifications"].exists)
        XCTAssertFalse(app.staticTexts["Default reminder time"].exists)
        capture("Audit preferences", app)
        tap("close-preferences", app); tap("plant-Snake Plant", app)
        XCTAssertTrue(app.navigationBars["Plant"].exists)
        capture("Audit plant details", app)
        tap("Plant options", app); tap("Edit plant", app)
        XCTAssertFalse(app.textFields["Species (optional)"].exists)
        XCTAssertFalse(app.textFields["Room or location"].exists)
        XCTAssertFalse(app.switches["I know when I last watered"].exists)
        capture("Audit edit plant", app)
        tap("edit-plant-photo", app)
        XCTAssertTrue(app.buttons["change-plant-photo"].exists)
        capture("Audit photo viewer", app)
        tap("Done", app)
        let name = app.textFields["plant-name-field"]; name.tap()
        let previousName = name.value as? String ?? ""
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: previousName.count) + "Desk snake")
        tap("save-plant", app)
        let identity = app.descendants(matching: .any).matching(identifier: "plant-detail-identity").firstMatch
        XCTAssertTrue(identity.label.contains("Dracaena trifasciata"))
        XCTAssertTrue(identity.label.contains("Desk snake"))
        let location = app.descendants(matching: .any).matching(identifier: "plant-detail-location").firstMatch
        for _ in 0..<4 { if location.exists { break }; app.swipeUp() }
        XCTAssertEqual(location.value as? String, "Living room")
        app.navigationBars["Plant"].buttons.firstMatch.tap()
        tap("plant-Desk snake", app); tap("start-observation", app)
        capture("Audit final observation areas", app)
        tap("Cancel", app)
        tap("plant-all-activity", app)
        XCTAssertTrue(app.navigationBars["Plant activity"].waitForExistence(timeout: 5))
    }
    func testDuplicatePlantGetsNicknameHintAndNamedSuccess() {
        let app = launch(); tap("home-add-plant", app); tap("select-species-Snake Plant", app)
        XCTAssertTrue(app.staticTexts["duplicate-plant-hint"].exists)
        XCTAssertTrue(app.navigationBars["Add plant"].exists)
        tap("overlay-continue-plant", app); tap("Choose later", app)
        tap("setup-status-Looking good", app); tap("overlay-save-plant", app)
        XCTAssertTrue(app.staticTexts["care-feedback-title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["care-feedback-title"].label, "Snake Plant added")
    }
    func testRemovalHasCancelAndNamedConfirmation() {
        let app = launch(); tap("plant-Snake Plant", app); tap("Plant options", app); tap("Remove plant", app)
        XCTAssertTrue(app.alerts["Remove Snake Plant?"].exists)
        app.alerts.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Plant"].exists)
        tap("Plant options", app); tap("Remove plant", app); app.alerts.buttons["Remove"].tap()
        XCTAssertTrue(app.staticTexts["My plants (4)"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["care-feedback-title"].label, "Snake Plant removed")
        capture("Audit removal feedback", app)
    }
    func testAtomicTasksThenOptionalCheckInAndNeutralUndo() {
        let app = launch(); newInspection(app)
        completeInspection(app)
        XCTAssertTrue(app.buttons["skip-completion-check-in"].waitForExistence(timeout: 5))
        capture("Audit optional progress check", app)
        tap("skip-completion-check-in", app)
        tap("undo-plan-task", app)
        XCTAssertEqual(app.staticTexts["care-feedback-title"].label, "Action reopened")
        capture("Audit neutral undo", app)
        dismissFeedback(app); tap("plant-next-care-task", app)
        XCTAssertTrue(app.staticTexts["Inspect leaf changes"].exists)
    }
    func testScheduleAfterCompletionOpensProgressChoices() {
        let app = launch(); newInspection(app); completeInspection(app)
        tap("schedule-completion-check-in", app); dismissFeedback(app)
        tap("plant-next-care-task", app)
        XCTAssertTrue(app.navigationBars["Check progress"].exists)
        capture("Audit progress choices", app)
        tap("Same", app); tap("finish-plan-task", app)
        XCTAssertTrue(app.staticTexts["care-feedback-title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(identifier: "care-feedback-title").count, 1)
        XCTAssertEqual(app.staticTexts["care-feedback-title"].label, "Check-in saved")
        XCTAssertFalse(app.buttons["dismiss-care-feedback"].exists)
        capture("Parity native check-in saved", app)
    }
    func testLastSoilCheckIsDatedHistoryOutsideCareActions() {
        let app = launch(); tap("See all", app); tap("all-plant-Rubber Plant", app)
        let summary = app.descendants(matching: .any).matching(identifier: "plant-last-care-summary").firstMatch
        for _ in 0..<4 { if !summary.isHittable { app.swipeUp() } }
        XCTAssertTrue(summary.waitForExistence(timeout: 5))
        XCTAssertTrue(summary.label.contains("Last soil check"))
        XCTAssertTrue(summary.label.contains("Not sure"))
        XCTAssertTrue(summary.label.contains("Will check later"))
        XCTAssertFalse(app.buttons["plant-last-care-summary"].exists)
        capture("Native dated care history", app)
    }

}
