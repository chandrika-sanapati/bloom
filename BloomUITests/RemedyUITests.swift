import XCTest

@MainActor final class RemedyUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private func capture(_ name: String, _ app: XCUIApplication) {
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }
    private func reveal(_ element: XCUIElement, app: XCUIApplication) {
        let footer = app.buttons.matching(NSPredicate(format: "identifier IN %@", ["assessment-continue", "start-care-plan", "leaf-start-care-plan", "finish-plan-task"])).allElementsBoundByIndex.last
        let bottom = footer?.frame.minY ?? app.frame.maxY - 24
        let top = (app.navigationBars.allElementsBoundByIndex.filter { $0.isHittable }.map { $0.frame.maxY }.max() ?? 132) + 8
        for _ in 0..<6 {
            if element.exists {
                let frame = element.frame
                if element.isHittable && frame.minY > top && frame.maxY < bottom - 4 { return }
                let down = frame.minY < top
                app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: down ? 0.4 : 0.7)).press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: down ? 0.65 : 0.4)))
            } else { app.swipeUp() }
        }
    }
    private func choose(_ id: String, _ value: String, app: XCUIApplication) {
        let picker = app.buttons[id]
        reveal(picker, app: app)
        if picker.label.contains(value) { return }
        picker.tap(); app.buttons[value].tap()
    }
    private func assess(_ app: XCUIApplication, signs: String, extent: String) {
        choose("assessment-signs", signs, app: app)
        choose("assessment-location", "Where leaves join stems", app: app)
        choose("assessment-extent", extent, app: app)
        choose("assessment-placement", "Indoors", app: app)
        capture("14 Native assessment", app)
        app.buttons["assessment-continue"].tap()
        XCTAssertTrue(app.navigationBars["What could help"].waitForExistence(timeout: 5))
    }
    private func openSavedObservation(_ app: XCUIApplication) {
        app.segmentedControls["home-care-picker"].buttons["Activity"].tap()
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "home-activity-")).firstMatch.tap()
        let next = app.buttons["find-next-steps"]; reveal(next, app: app); next.tap()
        if app.buttons["leaf-check-pests"].waitForExistence(timeout: 2) {
            let checks = app.buttons["leaf-check-pests"]; reveal(checks, app: app); checks.tap()
        }
        XCTAssertTrue(app.navigationBars["Take a closer look"].waitForExistence(timeout: 5))
    }
    private func clearBanner(_ app: XCUIApplication) {
        if app.buttons["dismiss-care-feedback"].exists { app.buttons["dismiss-care-feedback"].tap() }
    }
    private func openAcceptedPlan(_ app: XCUIApplication) {
        clearBanner(app)
        let plantLink = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "plant-care-plan-")).firstMatch
        let recordLink = app.buttons["view-care-plan"]
        let link = recordLink.exists ? recordLink : plantLink
        reveal(link, app: app); link.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
    private func finishAction(_ id: String, app: XCUIApplication) {
        clearBanner(app)
        let action = app.buttons[id]; reveal(action, app: app); action.tap()
        XCTAssertTrue(app.navigationBars["Care action"].waitForExistence(timeout: 5))
        app.buttons["finish-plan-task"].tap()
        XCTAssertTrue(app.staticTexts["Action recorded"].waitForExistence(timeout: 5))
        if app.buttons["schedule-completion-check-in"].exists { app.buttons["schedule-completion-check-in"].tap() }
        capture("17 Native care action saved", app)

    }
    func testObservationToCarePlanActionsAndExplicitResolution() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        app.buttons["plant-Snake Plant"].tap(); app.buttons["start-observation"].tap()
        app.buttons["observation-area-pests"].tap()
        app.buttons["Visible insects"].tap(); app.buttons["continue-observation"].tap(); app.buttons["save-change"].tap()
        XCTAssertTrue(app.buttons["leaf-start-care-plan"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Change saved"].exists)
        capture("53 Native pest causes after saving", app)
        let checks = app.buttons["leaf-check-pests"]; reveal(checks, app: app); checks.tap()
        assess(app, signs: "White cotton-like clusters", extent: "A small, reachable area")
        XCTAssertTrue(app.staticTexts["Possible mealybugs"].exists)
        capture("15 Native explained care plan", app)
        app.buttons["start-care-plan"].tap()
        openAcceptedPlan(app)
        XCTAssertTrue(app.navigationBars["Care plan"].waitForExistence(timeout: 5))
        capture("16 Native accepted care plan", app)
        finishAction("plan-step-separate", app: app)
        finishAction("plan-step-removeBugs", app: app)
        clearBanner(app)
        let review = app.buttons["plan-step-review"]; reveal(review, app: app); XCTAssertTrue(review.exists); review.tap()
        let better = app.buttons["Better"]; reveal(better, app: app); better.tap()
        let clear = app.switches["progress-no-new-signs"]; reveal(clear, app: app)
        if clear.switches.firstMatch.exists { clear.switches.firstMatch.tap() } else { clear.tap() }
        XCTAssertEqual(clear.value as? String, "1")
        capture("18 Native compare plan progress", app)
        app.buttons["finish-plan-task"].tap()
        XCTAssertTrue(app.staticTexts["Check-in saved"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["resolve-after-check"].exists)
        app.buttons["resolve-after-check"].tap(); app.buttons["Mark resolved"].tap()
        clearBanner(app)
        XCTAssertTrue(app.staticTexts["Resolved"].waitForExistence(timeout: 5))
        capture("19 Native explicitly resolved plan", app)
    }
    func testUncertainSignsOfferInspectionAndAllowNoFollowUp() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--uitesting-pest"]; app.launch()
        openSavedObservation(app)
        assess(app, signs: "Fine webbing", extent: "A small, reachable area")
        XCTAssertTrue(app.staticTexts["Look a little closer"].exists)
        XCTAssertFalse(app.staticTexts["Possible mealybugs"].exists)
        XCTAssertFalse(app.switches["plan-follow-up-toggle"].exists)
        app.buttons["start-care-plan"].tap()
        openAcceptedPlan(app)
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
        openAcceptedPlan(app)
        XCTAssertTrue(app.buttons["plan-step-askExpert"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["plan-step-removeBugs"].exists)
    }
    func testActionCanBeRescheduledSkippedAndUndone() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--uitesting-plan"]; app.launch()
        let action = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "care-plan-task-", "Keep this plant separate")).firstMatch
        reveal(action, app: app); action.tap()
        app.buttons["Change the date or task"].tap()
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
        let worse = app.buttons["Worse"]; reveal(worse, app: app); worse.tap()
        app.buttons["finish-plan-task"].tap()
        XCTAssertTrue(app.staticTexts["Check-in saved"].waitForExistence(timeout: 5))
        app.buttons["reassess-after-check"].tap()
        XCTAssertTrue(app.buttons["leaf-check-pests"].waitForExistence(timeout: 5))
        let checks = app.buttons["leaf-check-pests"]; reveal(checks, app: app); checks.tap()
        choose("assessment-extent", "Several areas or heavy damage", app: app)
        app.buttons["assessment-continue"].tap(); app.buttons["start-care-plan"].tap()
        XCTAssertTrue(app.staticTexts["Care plan added"].waitForExistence(timeout: 5))
        clearBanner(app)
        app.buttons["plant-Snake Plant"].tap()
        openAcceptedPlan(app)
        XCTAssertTrue(app.buttons["plan-step-askExpert"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["plan-step-removeBugs"].exists)
        capture("21 Native reassessed plan", app)
    }
}
