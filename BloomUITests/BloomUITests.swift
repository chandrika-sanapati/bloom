import XCTest

final class BloomUITests: XCTestCase {
    @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = name; shot.lifetime = .keepAlways; add(shot)
    }
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    func testCareCheckCanBeSavedAndUndone() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        capture("74 Native home heading hierarchy", app)
        app.buttons["plant-Snake Plant"].tap()
        let check = app.buttons["start-check"]
        if !check.isHittable { app.swipeUp() }
        check.tap()
        XCTAssertTrue(app.buttons["continue-check"].exists)
        XCTAssertFalse(app.buttons["continue-check"].isEnabled)
        capture("65 Native visible disabled action", app)
        capture("75 Native neutral text only disabled action", app)
        app.buttons["Dry"].tap()
        XCTAssertTrue(app.buttons["continue-check"].isEnabled)
        capture("03 Native soil check", app)
        app.buttons["continue-check"].tap()
        capture("04 Native decision", app)
        app.swipeUp()
        app.buttons["Will check later"].tap()
        app.buttons["save-check"].tap()
        XCTAssertTrue(app.staticTexts["Check saved"].waitForExistence(timeout: 5))
        capture("05 Native saved record", app)
        app.buttons["undo-record"].tap()
        XCTAssertTrue(app.buttons["start-check"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testChangeCanBeRecordedWithoutOptionalContext() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        app.buttons["plant-Snake Plant"].tap()
        app.buttons["start-observation"].tap()
        app.buttons["observation-area-leaves"].tap()
        app.buttons["Yellowing leaves"].tap()
        app.buttons["continue-observation"].tap()
        app.buttons["save-change"].tap()
        XCTAssertTrue(app.buttons["leaf-start-care-plan"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Change saved"].exists)
        app.buttons["close-guidance"].tap()
        XCTAssertTrue(app.navigationBars["Plant"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testHeaderStaysPinnedAndCollectionAddOpensSearchPage() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        let header = app.buttons["home-preferences"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        let initialY = header.frame.minY
        app.segmentedControls["home-care-picker"].buttons["Activity"].tap()
        app.swipeUp()
        XCTAssertEqual(header.frame.minY, initialY, accuracy: 1)
        let add = app.buttons["home-add-plant"]
        if !add.isHittable { app.swipeDown() }
        XCTAssertEqual(add.label, "Add plant")
        XCTAssertTrue(add.isHittable)
        XCTAssertEqual(add.frame.minY, header.frame.minY, accuracy: 1)
        XCTAssertGreaterThan(add.frame.minX, header.frame.maxX)
        XCTAssertFalse(app.scrollViews["home-plant-carousel"].exists)
        XCTAssertFalse(app.buttons["floating-add-plant"].exists)
        add.tap()
        XCTAssertTrue(app.navigationBars["Add plant"].waitForExistence(timeout: 5))
        let field = app.textFields["plant-search-field"]
        XCTAssertTrue(field.isHittable)
        XCTAssertFalse(app.buttons["plant-search-scanner"].exists)
        XCTAssertFalse(app.buttons["Sheet Grabber"].exists)
        XCTAssertFalse(app.buttons["overlay-search-plant"].exists)
        app.navigationBars["Add plant"].buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["home-add-plant"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["My plants (5)"].exists)
    }

    @MainActor
    func testSearchPageAddsPlantAndKeepsTheCollectionAccessible() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        app.buttons["home-add-plant"].tap()
        let search = app.textFields["plant-search-field"]
        search.tap(); search.typeText("Fern")
        app.buttons["Add \"Fern\" by name"].tap()
        app.buttons["overlay-continue-plant"].tap()
        XCTAssertFalse(app.buttons["setup-continue-location"].isEnabled)
        capture("66 Native visible disabled plant setup", app)
        capture("07 Native location", app)
        app.buttons["setup-room-menu"].tap()
        app.buttons["Living room"].tap()
        app.buttons["setup-continue-location"].tap()
        app.buttons["setup-status-Looking good"].tap()
        capture("08 Native current status", app)
        app.buttons["overlay-save-plant"].tap()
        XCTAssertTrue(app.navigationBars["Plant"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["start-check"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot()); screenshot.name = "Native plant detail after adding"; screenshot.lifetime = .keepAlways; add(screenshot)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["My plants (6)"].waitForExistence(timeout: 5))
        app.buttons["See all"].tap()
        let allSearch = app.searchFields.firstMatch; allSearch.tap(); allSearch.typeText("Fern")
        XCTAssertTrue(app.buttons["all-plant-Fern"].waitForExistence(timeout: 5))
    }
    @MainActor
    func testTwoCompleteCardsOpenDetailsAndPreserveSeeAll() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        XCTAssertTrue(app.staticTexts["My plants (5)"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.firstMatch.exists)
        XCTAssertFalse(app.buttons["home-care-tasks"].exists)
        XCTAssertFalse(app.buttons["plant-Snake Plant"].label.contains("Check soil"))
        XCTAssertTrue(app.buttons["plant-Monstera"].label.contains("Check soil"))
        capture("01 Native home", app)
        capture("64 Native compact plant collection", app)
        XCTAssertFalse(app.scrollViews["home-plant-carousel"].exists)
        XCTAssertFalse(app.staticTexts["Swipe for more plants"].exists)
        let cards = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "plant-"))
        XCTAssertEqual(cards.count, 2)
        let home = app.scrollViews["home-scroll"]
        for card in cards.allElementsBoundByIndex {
            XCTAssertTrue(card.isHittable)
            XCTAssertGreaterThanOrEqual(card.frame.minX, home.frame.minX)
            XCTAssertLessThanOrEqual(card.frame.maxX, home.frame.maxX)
        }
        app.buttons["See all"].tap()
        let lastPlant = app.buttons["all-plant-Office Snake"]
        for _ in 0..<3 { if !lastPlant.isHittable { app.swipeUp() } }
        XCTAssertTrue(lastPlant.waitForExistence(timeout: 5))
        lastPlant.tap()
        XCTAssertTrue(app.navigationBars["Plant"].waitForExistence(timeout: 5))
        let identity = app.descendants(matching: .any).matching(identifier: "plant-detail-identity").firstMatch
        XCTAssertTrue(identity.waitForExistence(timeout: 5))
        XCTAssertTrue(identity.label.contains("Office Snake"))
        XCTAssertTrue(identity.label.contains("Dracaena trifasciata"))
        capture("78 Native grouped plant name and scientific name", app)
        capture("70 Native edge to edge plant detail photo", app)
        app.navigationBars["Plant"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["My plants"].waitForExistence(timeout: 5))
        capture("67 Native compact all plants", app)
        let search = app.searchFields.firstMatch; search.tap(); search.typeText("Kitchen")
        XCTAssertTrue(app.buttons["all-plant-Kitchen Monstera"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testActivityOpensRecordsAndSearchableArchive() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        app.buttons["home-preferences"].tap()
        XCTAssertTrue(app.navigationBars["Preferences"].waitForExistence(timeout: 5))
        app.navigationBars["Preferences"].buttons["Close"].tap()
        let activity = app.segmentedControls["home-care-picker"].buttons["Activity"]
        activity.tap()
        let rows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "home-activity-"))
        XCTAssertEqual(rows.count, 5)
        capture("02 Native care activity", app)
        rows.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["Your record"].waitForExistence(timeout: 5))
        app.navigationBars["Your record"].buttons.firstMatch.tap()
        XCTAssertTrue(activity.isSelected)
        let allActivity = app.buttons["home-all-activity"]
        for _ in 0..<4 { if !allActivity.isHittable { app.swipeUp() } }
        allActivity.tap()
        XCTAssertTrue(app.navigationBars["All activity"].waitForExistence(timeout: 5))
        let search = app.searchFields.firstMatch; search.tap(); search.typeText("Monstera")
        let filtered = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "history-activity-"))
        XCTAssertGreaterThan(filtered.count, 0)
        for row in filtered.allElementsBoundByIndex { XCTAssertTrue(row.label.contains("Monstera")) }
    }

    @MainActor
    func testNoScheduledTasksKeepsAddingAndActivityAvailable() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--uitesting-no-tasks"]; app.launch()
        XCTAssertTrue(app.staticTexts["No tasks scheduled"].waitForExistence(timeout: 5))
        let add = app.buttons["home-add-plant"]
        XCTAssertTrue(add.isHittable)
        capture("10 Native home without tasks", app)
        add.tap()
        XCTAssertTrue(app.navigationBars["Add plant"].waitForExistence(timeout: 5))
        app.navigationBars["Add plant"].buttons.firstMatch.tap()
        app.segmentedControls["home-care-picker"].buttons["Activity"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "home-activity-")).firstMatch.exists)
    }

    @MainActor
    func testCompletedTaskAppearsInActivityWithoutLeavingHome() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        let task = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "reminder-task-", "Monstera")).firstMatch
        task.tap()
        app.buttons["Damp"].tap(); app.buttons["continue-check"].tap()
        app.buttons["Didn't water"].tap(); app.buttons["save-check"].tap()
        XCTAssertTrue(app.staticTexts["Check saved"].waitForExistence(timeout: 5))
        app.buttons["finish-record"].tap()
        let picker = app.segmentedControls["home-care-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        XCTAssertFalse(task.exists)
        picker.buttons["Activity"].tap()
        let latest = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "home-activity-")).firstMatch
        XCTAssertTrue(latest.label.contains("Checked Monstera"))
        XCTAssertTrue(latest.label.contains("waited"))
        capture("12 Native task saved to activity", app)
        latest.tap()
        XCTAssertTrue(app.navigationBars["Your record"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testEmptyActivityExplainsHowToStart() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--uitesting-no-tasks", "--uitesting-no-activity"]; app.launch()
        app.segmentedControls["home-care-picker"].buttons["Activity"].tap()
        XCTAssertTrue(app.staticTexts["Your care story starts here"].exists)
        XCTAssertTrue(app.buttons["home-add-plant"].isHittable)
        capture("13 Native empty activity", app)
    }

    @MainActor
    func testCatalogCardsShowCareAndLightAndOpenReview() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        app.buttons["home-add-plant"].tap()
        XCTAssertTrue(app.staticTexts["Choose a plant"].waitForExistence(timeout: 5))
        let snake = app.buttons["select-species-Snake Plant"]
        capture("06 Native discovery", app)
        XCTAssertTrue(snake.label.contains("Easy care"))
        XCTAssertTrue(snake.label.contains("Low light"))
        snake.tap()
        XCTAssertTrue(app.buttons["overlay-continue-plant"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["overlay-continue-plant"].isEnabled)
        XCTAssertTrue(app.buttons["setup-add-photo"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Dracaena trifasciata")).firstMatch.exists)
    }

    @MainActor
    func testReminderOpensTheMatchingCheckAndUndoReturnsToHome() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        let reminder = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "reminder-task-", "Monstera")).firstMatch
        if !reminder.isHittable { app.swipeUp() }
        reminder.tap()
        XCTAssertTrue(app.navigationBars["Check soil"].waitForExistence(timeout: 5))
        app.buttons["Damp"].tap(); app.buttons["continue-check"].tap()
        app.buttons["Didn't water"].tap(); app.buttons["save-check"].tap()
        XCTAssertTrue(app.staticTexts["Check saved"].waitForExistence(timeout: 5))
        app.buttons["undo-record"].tap()
        XCTAssertTrue(reminder.waitForExistence(timeout: 5))
    }

    @MainActor
    func testObservationReminderStaysOnConfirmationAfterItIsCompleted() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        app.swipeUp()
        let reminder = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "reminder-task-", "Office Snake")).firstMatch
        if !reminder.isHittable { app.swipeUp() }
        reminder.tap()
        XCTAssertTrue(app.navigationBars["Check in again"].waitForExistence(timeout: 5))
        app.buttons["About the same"].tap()
        app.buttons["Save follow-up"].tap()
        XCTAssertTrue(app.staticTexts["Follow-up saved"].waitForExistence(timeout: 5))
        app.buttons["finish-record"].tap()
        XCTAssertFalse(reminder.exists)
    }

}
