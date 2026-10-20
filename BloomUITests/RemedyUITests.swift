import XCTest

@MainActor final class RemedyUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private func capture(_ name: String, _ app: XCUIApplication) {
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }
    private func reveal(_ element: XCUIElement, app: XCUIApplication) {
        for _ in 0..<6 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
    }
    private func choose(_ id: String, _ value: String, app: XCUIApplication) {
        let picker = app.buttons[id]; reveal(picker, app: app); picker.tap(); app.buttons[value].tap()
    }
    private func assess(_ app: XCUIApplication, signs: String, extent: String) {
        let sign = app.buttons[signs]; reveal(sign, app: app); sign.tap()
        choose("assessment-location", "Where leaves join stems", app: app)
        choose("assessment-extent", extent, app: app)
        choose("assessment-placement", "Indoors", app: app)
        capture("14 Native assessment", app)
        app.buttons["assessment-continue"].tap()
        XCTAssertTrue(app.navigationBars["Your next steps"].waitForExistence(timeout: 5))
    }
    private func openSavedObservation(_ app: XCUIApplication) {
        app.segmentedControls["home-care-picker"].buttons["Activity"].tap()
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "home-activity-")).firstMatch.tap()
        let next = app.buttons["find-next-steps"]; reveal(next, app: app); next.tap()
        XCTAssertTrue(app.navigationBars["Understand the change"].waitForExistence(timeout: 5))
    }
    private func finishAction(_ id: String, app: XCUIApplication) {
        let action = app.buttons[id]; reveal(action, app: app); action.tap()
        XCTAssertTrue(app.navigationBars["Care action"].waitForExistence(timeout: 5))
        app.buttons["finish-plan-task"].tap()
        XCTAssertTrue(app.staticTexts["Action recorded"].waitForExistence(timeout: 5))
        capture("17 Native care action saved", app)
        app.buttons["close-plan-task"].tap()
    }
    func testObservationToCarePlanActionsAndExplicitResolution() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        app.buttons["plant-Snake Plant"].tap(); app.buttons["start-observation"].tap()
        app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Area")).firstMatch.tap(); app.buttons["Pests"].tap()
        app.buttons["Visible insects"].tap(); app.buttons["continue-observation"].tap(); app.buttons["save-change"].tap()
        XCTAssertTrue(app.staticTexts["Change saved"].waitForExistence(timeout: 5))
        capture("14 Native saved observation next steps", app)
        app.buttons["find-next-steps"].tap()
        assess(app, signs: "White cotton-like clusters", extent: "A small, reachable area")
        XCTAssertTrue(app.staticTexts["Possible mealybugs"].exists)
        capture("15 Native explained care plan", app)
        app.buttons["start-care-plan"].tap()
        XCTAssertTrue(app.navigationBars["Care plan"].waitForExistence(timeout: 5))
        capture("16 Native accepted care plan", app)
        finishAction("plan-step-separate", app: app)
        finishAction("plan-step-removeBugs", app: app)
        app.buttons["finish-plan-setup"].tap()
        app.buttons["finish-record"].tap()
        app.navigationBars["Snake Plant"].buttons.firstMatch.tap()
        let review = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "care-plan-task-", "Check the plan's progress")).firstMatch
        reveal(review, app: app); XCTAssertTrue(review.exists); review.tap()
        let clear = app.buttons["No visible signs now"]; reveal(clear, app: app); clear.tap()
        capture("18 Native compare plan progress", app)
        app.buttons["finish-plan-task"].tap()
        XCTAssertTrue(app.staticTexts["Check-in saved"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["resolve-after-check"].exists)
        app.buttons["resolve-after-check"].tap(); app.buttons["Mark resolved"].tap()
        app.buttons["View care plan"].tap()
        XCTAssertTrue(app.staticTexts["Resolved"].waitForExistence(timeout: 5))
        capture("19 Native explicitly resolved plan", app)
    }
    func testUncertainSignsOfferInspectionAndAllowNoFollowUp() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--uitesting-pest"]; app.launch()
        openSavedObservation(app)
        assess(app, signs: "Fine webbing", extent: "A small, reachable area")
        XCTAssertTrue(app.staticTexts["Look a little closer"].exists)
        XCTAssertFalse(app.staticTexts["Possible mealybugs"].exists)
        let follow = app.switches["plan-follow-up-toggle"]; reveal(follow, app: app); follow.tap()
        app.buttons["start-care-plan"].tap()
        XCTAssertTrue(app.navigationBars["Care plan"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["plan-step-inspect"].exists)
        XCTAssertFalse(app.buttons["plan-step-removeBugs"].exists)
        XCTAssertFalse(app.buttons["plan-step-review"].exists)
        capture("20 Native inspection alternative", app)
    }
    func testWidespreadDamageOffersHelpRatherThanSmallAreaTreatment() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--uitesting-pest"]; app.launch()
        openSavedObservation(app)
        assess(app, signs: "White cotton-like clusters", extent: "Several areas or heavy damage")
        XCTAssertTrue(app.staticTexts["Get help identifying the cause"].exists)
        app.buttons["start-care-plan"].tap()
        XCTAssertTrue(app.buttons["plan-step-askExpert"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["plan-step-removeBugs"].exists)
    }
    func testActionCanBeRescheduledSkippedAndUndone() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--uitesting-plan"]; app.launch()
        let action = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "care-plan-task-", "Keep this plant separate")).firstMatch
        reveal(action, app: app); action.tap()
        let schedule = app.buttons["reschedule-plan-task"]; reveal(schedule, app: app); schedule.tap()
        XCTAssertTrue(app.navigationBars["Task schedule"].waitForExistence(timeout: 5))
        app.navigationBars["Task schedule"].buttons["Save"].tap()
        let skip = app.buttons["skip-plan-action"]; reveal(skip, app: app); skip.tap(); app.buttons["Skip action"].tap()
        XCTAssertTrue(app.staticTexts["Action skipped"].waitForExistence(timeout: 5))
        app.buttons["undo-plan-task"].tap()
        XCTAssertTrue(action.waitForExistence(timeout: 5))
    }
    func testWorseProgressCanBeReassessedIntoRevisedPlan() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--uitesting-plan-review"]; app.launch()
        let review = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "care-plan-task-", "Check the plan's progress")).firstMatch
        reveal(review, app: app); review.tap()
        let worse = app.buttons["More signs or new damage"]; reveal(worse, app: app); worse.tap()
        app.buttons["finish-plan-task"].tap()
        XCTAssertTrue(app.staticTexts["Check-in saved"].waitForExistence(timeout: 5))
        app.buttons["reassess-after-check"].tap()
        choose("assessment-extent", "Several areas or heavy damage", app: app)
        app.buttons["assessment-continue"].tap(); app.buttons["start-care-plan"].tap()
        XCTAssertTrue(app.buttons["plan-step-askExpert"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["plan-step-removeBugs"].exists)
        capture("21 Native reassessed plan", app)
    }
}
