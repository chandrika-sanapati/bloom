import XCTest

@MainActor final class LeafCareUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private func capture(_ name: String, _ app: XCUIApplication) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }
    private func reveal(_ element: XCUIElement, _ app: XCUIApplication) {
        let footer = app.buttons.matching(NSPredicate(format: "identifier IN %@", ["assessment-continue", "start-care-plan", "leaf-start-care-plan", "finish-plan-task", "continue-observation", "save-change"])).allElementsBoundByIndex.last
        let hint = app.staticTexts["observation-selection-hint"]
        let bottom = min(footer?.frame.minY ?? app.frame.maxY - 24, hint.exists && hint.isHittable ? hint.frame.minY : .infinity)
        let top = (app.navigationBars.allElementsBoundByIndex.filter { $0.isHittable }.map { $0.frame.maxY }.max() ?? 132) + 8
        for _ in 0..<6 {
            if element.exists {
                let frame = element.frame
                if element.isHittable && frame.minY > top && frame.maxY < bottom - 4 { return }
                let down = frame.minY < top
                // Keep the scroll gesture inside the content, above any scaled footer.
                let available = max(40, bottom - top)
                let upper = top + available * 0.25
                let lower = top + available * 0.8
                let origin = app.coordinate(withNormalizedOffset: .zero)
                origin.withOffset(CGVector(dx: app.frame.width * 0.5, dy: down ? upper : lower))
                    .press(forDuration: 0.05, thenDragTo: origin.withOffset(CGVector(dx: app.frame.width * 0.5, dy: down ? lower : upper)))
            } else { app.swipeUp() }
        }
    }
    private func tap(_ id: String, _ app: XCUIApplication) {
        let b = app.buttons[id]; reveal(b, app)
        if id == "view-care-plan" { b.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap() } else { b.tap() }
    }
    private func choose(_ id: String, _ value: String, _ app: XCUIApplication) {
        let picker = app.buttons[id]; reveal(picker, app)
        if picker.label.contains(value) { return }
        picker.tap()
        let option = app.buttons.matching(NSPredicate(format: "label == %@ AND identifier != %@", value, "leaf-assessment-soil")).firstMatch
        // iOS may expose the picker through its legacy Button automation type.
        if !option.waitForExistence(timeout: 2) {
            picker.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        XCTAssertTrue(option.waitForExistence(timeout: 3))
        option.tap()
    }
    private func clearBanner(_ app: XCUIApplication) {
        if app.buttons["dismiss-care-feedback"].exists { app.buttons["dismiss-care-feedback"].tap() }
    }
    private func startSaved() -> XCUIApplication {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--uitesting-leaf"]; app.launch()
        app.segmentedControls["home-care-picker"].buttons["Past"].tap()
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "home-activity-")).firstMatch.tap()
        tap("find-next-steps", app)
        XCTAssertTrue(app.buttons["leaf-start-care-plan"].waitForExistence(timeout: 5)); return app
    }
    private func assess(_ app: XCUIApplication, soil: String = "dry", warning: String = "None of these") {
        tap("I've checked my plant", app); tap("leaf-soil-\(soil)", app)
        if soil == "dry" { choose("leaf-assessment-drainage", "Yes, water can drain out", app) }
        choose("leaf-assessment-warning", warning, app)
    }
    private func acceptFromRecord(_ app: XCUIApplication) {
        app.buttons["leaf-start-care-plan"].tap()
        XCTAssertTrue(app.navigationBars["Your record"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["finish-plan-setup"].exists)
        XCTAssertTrue(app.staticTexts["Care plan added"].exists)
        clearBanner(app); tap("view-care-plan", app)
        XCTAssertTrue(app.navigationBars["Care plan"].waitForExistence(timeout: 5))
    }
    private func newChange(_ app: XCUIApplication, area: String = "leaves", symptom: String = "Dropping leaves") {
        app.buttons["plant-Snake Plant"].tap(); app.buttons["start-observation"].tap()
        tap("observation-area-\(area)", app); tap(symptom, app)
        app.buttons["continue-observation"].tap(); app.buttons["save-change"].tap()
        XCTAssertTrue(app.navigationBars["What could help"].waitForExistence(timeout: 5))
    }
    private func completeInspection(_ app: XCUIApplication, schedule: Bool) {
        for step in ["checkSoilMoisture", "checkGrowingConditions", "checkLeafChanges"] {
            clearBanner(app); tap("plan-step-\(step)", app); app.buttons["finish-plan-task"].tap()
        }
        let next = app.buttons[schedule ? "schedule-completion-check-in" : "skip-completion-check-in"]
        XCTAssertTrue(next.waitForExistence(timeout: 5)); next.tap()
    }
    func testSavedLeafChangeNextStepsOpensClosesAndReopensFromActivity() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch(); newChange(app)
        XCTAssertTrue(app.staticTexts["Change saved"].exists)
        capture("56 Native straightforward change guidance", app)
        app.buttons["close-guidance"].tap()
        XCTAssertTrue(app.navigationBars["Plant"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["finish-record"].exists)
        clearBanner(app); app.navigationBars["Plant"].buttons.firstMatch.tap()
        app.segmentedControls["home-care-picker"].buttons["Past"].tap()
        let records = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "home-activity-", "Dropping leaves"))
        XCTAssertEqual(records.count, 1); records.firstMatch.tap(); tap("find-next-steps", app)
        XCTAssertTrue(app.navigationBars["What could help"].waitForExistence(timeout: 5)); app.buttons["close-guidance"].tap()
        XCTAssertTrue(app.navigationBars["Your record"].waitForExistence(timeout: 5))
        tap("Edit record", app); XCTAssertTrue(app.buttons["save-change"].waitForExistence(timeout: 5))
        app.buttons["save-change"].tap(); XCTAssertTrue(app.buttons["leaf-start-care-plan"].waitForExistence(timeout: 5))
        app.buttons["close-guidance"].tap(); XCTAssertTrue(app.navigationBars["Your record"].waitForExistence(timeout: 5))
    }
    func testAreaAndChangeCardsCanBeRevisedAndSavedDirectlyToACarePlan() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        app.buttons["plant-Snake Plant"].tap(); app.buttons["start-observation"].tap()
        capture("76 Native observation heading hierarchy", app)
        app.buttons["observation-area-leaves"].tap(); app.buttons["Brown edges"].tap()
        app.navigationBars["What looks different?"].buttons.firstMatch.tap(); app.buttons["observation-area-stems"].tap()
        XCTAssertTrue(app.buttons["continue-observation"].exists); XCTAssertFalse(app.buttons["continue-observation"].isEnabled); app.buttons["Changed color"].tap()
        app.navigationBars["What looks different?"].buttons.firstMatch.tap(); app.buttons["observation-area-leaves"].tap()
        XCTAssertTrue(app.buttons["continue-observation"].exists); XCTAssertFalse(app.buttons["continue-observation"].isEnabled)
        capture("69 Native visible disabled observation action", app)
        app.buttons["Dropping leaves"].tap(); app.buttons["continue-observation"].tap(); app.buttons["save-change"].tap()
        XCTAssertTrue(app.buttons["leaf-start-care-plan"].waitForExistence(timeout: 5))
        capture("77 Native guidance heading hierarchy and text actions", app)
        app.buttons["leaf-start-care-plan"].tap()
        XCTAssertTrue(app.navigationBars["Plant"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Care plan added"].exists); XCTAssertFalse(app.buttons["finish-record"].exists)
        capture("57 Native added care returns to plant", app)
        clearBanner(app); tap("plant-next-care-task", app)
        XCTAssertTrue(app.navigationBars["Care action"].waitForExistence(timeout: 5))
        capture("58 Native concise care task", app)
        app.buttons["finish-plan-task"].tap()
        XCTAssertTrue(app.navigationBars["Plant"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Action recorded"].exists)
        XCTAssertTrue(app.staticTexts["care-feedback-detail"].label.hasPrefix("Next:"))
        capture("59 Native action saved without another page", app)
        app.buttons["undo-plan-task"].tap()
        XCTAssertFalse(app.staticTexts["Action recorded"].exists)
        tap("plant-next-care-task", app); XCTAssertTrue(app.navigationBars["Care action"].waitForExistence(timeout: 5))
    }
    func testCustomChangeCardsWorkWithAccessibilityTextWithoutInventingADiagnosis() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]; app.launch()
        let plant = app.buttons["plant-Snake Plant"]
        XCTAssertTrue(plant.waitForExistence(timeout: 5))
        capture("71 Native compact collection accessibility text", app)
        // Activate the name region, clear of the carousel's portrait and horizontal scrolling gesture.
        plant.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)).tap()
        XCTAssertTrue(app.navigationBars["Plant"].waitForExistence(timeout: 5))
        tap("start-observation", app); tap("observation-area-whole", app); tap("Something else", app)
        XCTAssertTrue(app.buttons["continue-observation"].exists); XCTAssertFalse(app.buttons["continue-observation"].isEnabled)
        capture("68 Native disabled observation accessibility text", app)
        let field = app.textViews["custom-observation"].exists ? app.textViews["custom-observation"] : app.textFields["custom-observation"]
        reveal(field, app); field.tap(); field.typeText("New marks on the pot")
        app.buttons["continue-observation"].tap(); app.buttons["save-change"].tap()
        XCTAssertTrue(app.buttons["leaf-start-care-plan"].waitForExistence(timeout: 5)); app.buttons["leaf-start-care-plan"].tap()
        XCTAssertTrue(app.navigationBars["Plant"].waitForExistence(timeout: 5))
        capture("61 Native simplified flow accessibility text", app)
        clearBanner(app); tap("plant-next-care-task", app)
        XCTAssertTrue(app.staticTexts["Check soil moisture"].exists)
        XCTAssertFalse(app.buttons["leaf-watering-decision"].exists)
    }
    func testNewPestChangeCanStartAnInspectionPlanWithoutIdentifyingThePest() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch(); newChange(app, area: "pests", symptom: "Visible insects")
        XCTAssertFalse(app.buttons["assessment-continue"].exists); app.buttons["leaf-start-care-plan"].tap()
        XCTAssertTrue(app.navigationBars["Plant"].waitForExistence(timeout: 5)); clearBanner(app); tap("plant-next-care-task", app)
        XCTAssertTrue(app.staticTexts["Inspect the affected area"].exists)
        XCTAssertFalse(app.staticTexts["Careful physical removal"].exists)
    }
    func testRecordLeafDropChooseActionAndCompareWithExplicitResolution() {
        let app = startSaved(); assess(app); acceptFromRecord(app)
        tap("plan-step-waterDryRoots", app); XCTAssertFalse(app.buttons["finish-plan-task"].isEnabled)
        tap("Watered it", app); app.buttons["finish-plan-task"].tap()
        XCTAssertTrue(app.buttons["schedule-completion-check-in"].waitForExistence(timeout: 5))
        app.buttons["schedule-completion-check-in"].tap()
        XCTAssertTrue(app.staticTexts["Action recorded"].waitForExistence(timeout: 5)); clearBanner(app)
        tap("plan-step-review", app)
        XCTAssertTrue(app.staticTexts["Checking early keeps your scheduled check-in."].exists)
        capture("72 Native compact progress choices", app)
        tap("Better", app); let toggle = app.switches["progress-no-new-signs"]; reveal(toggle, app)
        if toggle.switches.firstMatch.exists { toggle.switches.firstMatch.tap() } else { toggle.tap() }
        XCTAssertEqual(toggle.value as? String, "1")
        capture("60 Native simple progress choices", app)
        app.buttons["finish-plan-task"].tap(); XCTAssertTrue(app.staticTexts["Check-in saved"].waitForExistence(timeout: 5))
        app.buttons["resolve-after-check"].tap(); app.buttons["Mark resolved"].tap()
        XCTAssertTrue(app.staticTexts["Issue resolved"].waitForExistence(timeout: 5)); clearBanner(app)
        for _ in 0..<5 { if !app.staticTexts["Resolved"].exists { app.swipeDown() } }
        XCTAssertTrue(app.staticTexts["Resolved"].exists)
    }
    func testNoChecksCanAddCareTaskAndCompleteItBeforeTheOptionalCheckIn() {
        let app = startSaved(); XCTAssertFalse(app.buttons["leaf-soil-dry"].exists); acceptFromRecord(app)
        completeInspection(app, schedule: true); XCTAssertTrue(app.navigationBars["Care plan"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["care-feedback-detail"].label.hasPrefix("Check again"))
        XCTAssertFalse(app.navigationBars["Saved"].exists)
        clearBanner(app); tap("plan-step-review", app); tap("Same", app)
        app.buttons["finish-plan-task"].tap()
        XCTAssertTrue(app.staticTexts["Check-in saved"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["resolve-after-check"].exists)
        app.buttons["schedule-after-check"].tap()
        XCTAssertTrue(app.navigationBars["Next check-in"].waitForExistence(timeout: 5))
        app.navigationBars["Next check-in"].buttons["Save"].tap()
        XCTAssertTrue(app.staticTexts["Next check-in set"].waitForExistence(timeout: 5))
        clearBanner(app)
        app.navigationBars["Care plan"].buttons.firstMatch.tap()
        app.navigationBars["Your record"].buttons.firstMatch.tap()
        let activity = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "home-activity-", "Inspect leaf changes")).firstMatch
        reveal(activity, app); activity.tap()
        XCTAssertTrue(app.navigationBars["Your record"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Action completed"].exists)
        XCTAssertFalse(app.staticTexts["Done"].exists)
        capture("73 Native compact completed action record", app)
        tap("View care plan", app)
        XCTAssertTrue(app.navigationBars["Care plan"].waitForExistence(timeout: 5))
    }
    func testClearChecksReturnsToInspectionWithoutErasingTheObservation() {
        let app = startSaved(); assess(app); tap("leaf-reset-checks", app)
        let title = app.staticTexts["leaf-recommendation-title"]; reveal(title, app); XCTAssertEqual(title.label, "Check the cause before treating")
        app.buttons["close-guidance"].tap(); XCTAssertTrue(app.staticTexts["Dropping leaves"].exists)
    }
    func testAccessibleTextKeepsTheCareActionAvailableWithoutChecks() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]; app.launch()
        newChange(app); XCTAssertTrue(app.buttons["leaf-start-care-plan"].isHittable)
        app.buttons["leaf-start-care-plan"].tap(); XCTAssertTrue(app.navigationBars["Plant"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["dismiss-care-feedback"].isHittable)
    }
    func testSoggyMixSuggestsDrainageAndActionCanBeUndone() {
        let app = startSaved(); assess(app, soil: "soggy"); XCTAssertTrue(app.staticTexts["Let excess water drain"].exists)
        acceptFromRecord(app); tap("plan-step-drainExcessWater", app); app.buttons["finish-plan-task"].tap()
        XCTAssertTrue(app.buttons["skip-completion-check-in"].waitForExistence(timeout: 5)); app.buttons["skip-completion-check-in"].tap()
        XCTAssertTrue(app.staticTexts["Action recorded"].waitForExistence(timeout: 5)); app.buttons["undo-plan-task"].tap()
        XCTAssertTrue(app.buttons["plan-step-drainExcessWater"].exists); XCTAssertFalse(app.buttons["plan-step-review"].exists)
    }
    func testUncertainChecksOfferInspectionAndFollowUpCanBeDeclined() {
        let app = startSaved(); acceptFromRecord(app)
        completeInspection(app, schedule: false)
        XCTAssertTrue(app.staticTexts["Action recorded"].waitForExistence(timeout: 5)); clearBanner(app)
        XCTAssertFalse(app.buttons["plan-step-review"].exists)
    }
    func testSoftStemsOfferHelpWithoutAThreeDayWait() {
        let app = startSaved(); assess(app, warning: "Soft or blackened stems/base")
        let title = app.staticTexts["leaf-recommendation-title"]; reveal(title, app); XCTAssertEqual(title.label, "Get help before waiting")
        acceptFromRecord(app); XCTAssertTrue(app.buttons["plan-step-askExpert"].exists)
        XCTAssertFalse(app.buttons["plan-step-waterDryRoots"].exists); XCTAssertFalse(app.buttons["plan-step-review"].exists)
    }
    func testChecksResumeAndVisiblePestsConnectToTheExistingPestFlow() {
        let app = startSaved(); tap("I've checked my plant", app); tap("leaf-soil-dry", app); app.buttons["close-guidance"].tap()
        tap("find-next-steps", app); tap("I've checked my plant", app); XCTAssertTrue(app.buttons["leaf-soil-dry"].isSelected)
        choose("leaf-assessment-warning", "Insects, clusters, or webbing", app); tap("leaf-check-pests", app)
        choose("assessment-signs", "White cotton-like clusters", app); choose("assessment-location", "Where leaves join stems", app)
        choose("assessment-extent", "A small, reachable area", app); choose("assessment-placement", "Indoors", app)
        app.buttons["assessment-continue"].tap(); app.buttons["start-care-plan"].tap()
        XCTAssertTrue(app.navigationBars["Your record"].waitForExistence(timeout: 5)); clearBanner(app); tap("view-care-plan", app)
        XCTAssertTrue(app.buttons["plan-step-removeBugs"].waitForExistence(timeout: 5))
    }
    func testOptionalPestChecksCanContinueWithoutAnswersAndStillOfferInspection() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        newChange(app, area: "pests", symptom: "Visible insects")
        tap("leaf-check-pests", app)
        XCTAssertTrue(app.navigationBars["Take a closer look"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["assessment-continue"].isEnabled)
        XCTAssertTrue(app.buttons["assessment-signs"].label.contains("Not checked"))
        app.buttons["assessment-continue"].tap()
        XCTAssertTrue(app.staticTexts["Look a little closer"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Possible mealybugs"].exists)
        app.buttons["start-care-plan"].tap()
        XCTAssertTrue(app.navigationBars["Plant"].waitForExistence(timeout: 5))
        clearBanner(app)
        XCTAssertTrue(app.buttons["plant-next-care-task"].label.contains("Inspect the affected area"))
        capture("Parity optional pest checks preserve inspection", app)
    }

}
