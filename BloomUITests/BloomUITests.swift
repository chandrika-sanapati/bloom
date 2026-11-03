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
        app.buttons["plant-Snake Plant-Living-room"].tap()
        let check = app.buttons["start-check"]
        if !check.isHittable { app.swipeUp() }
        check.tap()
        XCTAssertTrue(app.buttons["save-check"].exists)
        XCTAssertFalse(app.buttons["save-check"].isEnabled)
        XCTAssertTrue(app.buttons["soil-choice-Dry"].exists)
        XCTAssertTrue(app.buttons["care-decision-Will check later"].exists)
        capture("65 Native visible disabled action", app)
        capture("75 Native neutral text only disabled action", app)
        app.buttons["Dry"].tap()
        XCTAssertFalse(app.buttons["save-check"].isEnabled)
        app.buttons["care-decision-Will check later"].tap()
        XCTAssertTrue(app.buttons["save-check"].isEnabled)
        capture("04 Native decision", app)
        app.buttons["save-check"].tap()
        XCTAssertTrue(app.buttons["start-check"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Check saved"].exists)
        XCTAssertTrue(app.buttons["undo-record"].exists)
        capture("05 Native check saved in place", app)
        app.buttons["undo-record"].tap()
        XCTAssertTrue(app.buttons["start-check"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testChangeCanBeRecordedWithoutOptionalContext() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        app.buttons["plant-Snake Plant-Living-room"].tap()
        app.buttons["start-observation"].tap()
        app.buttons["observation-area-leaves"].tap()
        app.buttons["Yellowing leaves"].tap()
        app.buttons["continue-observation"].tap()
        app.buttons["save-change"].tap()
        XCTAssertTrue(app.buttons["leaf-start-care-plan"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Change saved"].exists)
        app.buttons["close-guidance"].tap()
        XCTAssertTrue(app.navigationBars["Plant"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testHeaderStaysPinnedAndCollectionAddOpensSearchPage() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        let header = app.buttons["home-preferences"]
        XCTAssertTrue(header.waitForExistence(timeout: 5))
        let initialY = header.frame.minY
        app.segmentedControls["home-care-picker"].buttons["Past"].tap()
        app.swipeUp()
        XCTAssertEqual(header.frame.minY, initialY, accuracy: 1)
        let add = app.buttons["home-add-plant"]
        if !add.isHittable { app.swipeDown() }
        XCTAssertEqual(add.label, "Add plant")
        XCTAssertTrue(add.isHittable)
        XCTAssertEqual(add.frame.minY, header.frame.minY, accuracy: 1)
        XCTAssertGreaterThan(add.frame.minX, header.frame.maxX)
        XCTAssertTrue(app.scrollViews["home-plant-carousel"].exists)
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
    func testSearchPageAddsPlantAndReturnsHomeWithConfirmation() {
        let app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
        app.buttons["home-add-plant"].tap()
        let search = app.textFields["plant-search-field"]
        search.tap(); search.typeText("Fern")
        app.buttons["Add \"Fern\" by name"].tap()
        XCTAssertTrue(app.navigationBars["Add plant"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Add details"].exists)
        XCTAssertFalse(app.buttons["setup-placement"].exists)
        XCTAssertFalse(app.textFields["setup-custom-location"].exists)
        XCTAssertFalse(app.buttons["setup-add-photo"].exists)
        app.buttons["overlay-save-plant"].tap()
        XCTAssertTrue(app.staticTexts["My plants (6)"].waitForExistence(timeout: 5))
        let addedMessage = app.staticTexts["care-feedback-title"]
        XCTAssertTrue(addedMessage.waitForExistence(timeout: 5))
        XCTAssertEqual(addedMessage.label, "Fern added")
        XCTAssertTrue(app.segmentedControls["home-care-picker"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot()); screenshot.name = "Home after adding plant"; screenshot.lifetime = .keepAlways; add(screenshot)
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
        XCTAssertFalse(app.buttons["plant-Snake Plant-Living-room"].label.contains("Check soil"))
        XCTAssertFalse(app.buttons["plant-Monstera-By-the-window"].label.contains("Check soil"))
        capture("01 Native home", app)
        capture("64 Native compact plant collection", app)
        XCTAssertTrue(app.scrollViews["home-plant-carousel"].exists)
        XCTAssertFalse(app.staticTexts["Swipe for more plants"].exists)
        let carousel = app.scrollViews["home-plant-carousel"]
        let cards = [app.buttons["plant-Snake Plant-Living-room"], app.buttons["plant-Monstera-By-the-window"]]
        let home = app.scrollViews["home-scroll"]
        for card in cards {
            XCTAssertTrue(card.isHittable)
            XCTAssertGreaterThanOrEqual(card.frame.minX, home.frame.minX)
            XCTAssertLessThanOrEqual(card.frame.maxX, home.frame.maxX)
        }
        let nextCard = app.buttons["plant-Rubber Plant"]
        XCTAssertTrue(nextCard.exists)
        XCTAssertLessThan(nextCard.frame.minX, carousel.frame.maxX)
        XCTAssertGreaterThan(nextCard.frame.maxX, carousel.frame.maxX)
        carousel.swipeLeft()
        let laterCards = ["plant-Rubber Plant", "plant-Monstera-Kitchen", "plant-Snake Plant-Workspace"].map { app.buttons[$0] }
        XCTAssertTrue(laterCards.contains { $0.exists && $0.isHittable && $0.frame.minX >= carousel.frame.minX && $0.frame.maxX <= carousel.frame.maxX })
        capture("Collection browse later plants", app)
        let first = app.buttons["plant-Snake Plant-Living-room"]
        for _ in 0..<3 {
            if first.exists && first.frame.minX >= carousel.frame.minX && first.isHittable { break }
            carousel.swipeRight()
        }
        XCTAssertTrue(first.isHittable)
        XCTAssertGreaterThanOrEqual(first.frame.minX, carousel.frame.minX)
        app.buttons["See all"].tap()
        let add = app.buttons["collection-add-plant"]
        XCTAssertTrue(add.isHittable)
        XCTAssertEqual(add.label, "Add plant")
        add.tap()
        XCTAssertTrue(app.navigationBars["Add plant"].waitForExistence(timeout: 5))
        app.navigationBars["Add plant"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["My plants"].waitForExistence(timeout: 5))
        let lastPlant = app.buttons["all-plant-Snake Plant-Workspace"]
        for _ in 0..<3 { if !lastPlant.isHittable { app.swipeUp() } }
        XCTAssertTrue(lastPlant.waitForExistence(timeout: 5))
        lastPlant.tap()
        XCTAssertTrue(app.navigationBars["Plant"].waitForExistence(timeout: 5))
        let identity = app.descendants(matching: .any).matching(identifier: "plant-detail-identity").firstMatch
        XCTAssertTrue(identity.waitForExistence(timeout: 5))
        XCTAssertTrue(identity.label.contains("Snake Plant"))
        XCTAssertTrue(identity.label.contains("Dracaena trifasciata"))
        capture("78 Native grouped plant name and scientific name", app)
        capture("70 Native edge to edge plant detail photo", app)
        app.navigationBars["Plant"].buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["My plants"].waitForExistence(timeout: 5))
        capture("67 Native compact all plants", app)
        let search = app.searchFields.firstMatch; search.tap(); search.typeText("Kitchen")
        XCTAssertTrue(app.buttons["all-plant-Monstera-Kitchen"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testActivityOpensRecordsAndSearchableArchive() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        app.buttons["home-preferences"].tap()
        XCTAssertTrue(app.navigationBars["Preferences"].waitForExistence(timeout: 5))
        app.navigationBars["Preferences"].buttons["Close"].tap()
        let activity = app.segmentedControls["home-care-picker"].buttons["Past"]
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
        XCTAssertTrue(app.staticTexts["Nothing scheduled"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "will appear here")).count, 0)
        let add = app.buttons["home-add-plant"]
        XCTAssertTrue(add.isHittable)
        capture("10 Native home without tasks", app)
        add.tap()
        XCTAssertTrue(app.navigationBars["Add plant"].waitForExistence(timeout: 5))
        app.navigationBars["Add plant"].buttons.firstMatch.tap()
        app.segmentedControls["home-care-picker"].buttons["Past"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "home-activity-")).firstMatch.exists)
    }

    @MainActor
    func testCompletedTaskAppearsInActivityWithoutLeavingHome() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        let task = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "reminder-task-", "Monstera")).firstMatch
        task.tap()
        app.buttons["Damp"].tap(); app.buttons["care-decision-Didn't water"].tap()
        app.buttons["save-check"].tap()
        XCTAssertTrue(app.segmentedControls["home-care-picker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Check saved"].exists)
        let picker = app.segmentedControls["home-care-picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        XCTAssertFalse(task.exists)
        picker.buttons["Past"].tap()
        let latest = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "home-activity-")).firstMatch
        XCTAssertTrue(latest.label.contains("Soil check"))
        XCTAssertTrue(latest.label.contains("Monstera"))
        capture("12 Native task saved to activity", app)
        latest.tap()
        XCTAssertTrue(app.navigationBars["Your record"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Damp · Didn't water"].exists)
    }

    @MainActor
    func testEmptyGardenShowsOnlyCenteredAddPlantCard() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        app.buttons["home-preferences"].tap()
        app.buttons["Start fresh without sample plants"].tap()
        app.buttons["Clear plants and records"].tap()
        XCTAssertTrue(app.buttons["empty-add-plant"].waitForExistence(timeout: 5))
        let picker = app.segmentedControls["home-care-picker"]
        XCTAssertFalse(picker.exists)
        XCTAssertFalse(app.staticTexts["No activity yet"].exists)
        XCTAssertTrue(app.buttons["empty-add-plant"].isHittable)
        XCTAssertFalse(app.buttons["home-add-plant"].exists)
        let card = app.otherElements.containing(.button, identifier: "empty-add-plant").firstMatch
        XCTAssertEqual(card.frame.midY, app.scrollViews["home-scroll"].frame.midY, accuracy: 40)
        capture("Empty garden centered add plant card", app)
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
        XCTAssertFalse(snake.label.contains("in My plants"))
        snake.tap()
        XCTAssertTrue(app.buttons["overlay-save-plant"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["overlay-save-plant"].isEnabled)
        app.buttons["setup-optional-details"].tap()
        XCTAssertTrue(app.buttons["setup-add-photo"].exists)
        XCTAssertTrue(app.buttons["setup-placement"].exists)
        XCTAssertTrue(app.staticTexts["First impression"].exists)
        XCTAssertTrue(app.buttons["setup-status-Looking good"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Dracaena trifasciata")).firstMatch.exists)
    }

    @MainActor
    func testReminderOpensTheMatchingCheckAndUndoReturnsToHome() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        let reminder = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "reminder-task-", "Monstera")).firstMatch
        if !reminder.isHittable { app.swipeUp() }
        reminder.tap()
        XCTAssertTrue(app.navigationBars["Check soil"].waitForExistence(timeout: 5))
        app.buttons["Damp"].tap(); app.buttons["care-decision-Didn't water"].tap()
        app.buttons["save-check"].tap()
        XCTAssertTrue(app.buttons["start-check"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Check saved"].exists)
        app.buttons["undo-record"].tap()
        XCTAssertTrue(reminder.waitForExistence(timeout: 5))
    }

    @MainActor
    func testObservationReminderStaysOnConfirmationAfterItIsCompleted() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        app.swipeUp()
        let reminder = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "reminder-task-", "Snake Plant")).firstMatch
        if !reminder.isHittable { app.swipeUp() }
        reminder.tap()
        XCTAssertTrue(app.navigationBars["Check in again"].waitForExistence(timeout: 5))
        app.buttons["About the same"].tap()
        app.buttons["Save follow-up"].tap()
        XCTAssertTrue(app.staticTexts["Follow-up saved"].waitForExistence(timeout: 5))
        app.buttons["finish-record"].tap()
        XCTAssertFalse(reminder.exists)
    }

    @MainActor
    func testReminderPresetsStayInDraftUntilSavedAndCancelLeavesNoTask() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--uitesting-no-tasks"]; app.launch()
        app.buttons["plant-Snake Plant-Living-room"].tap()
        let reminder = app.buttons["reminder-options"]
        for _ in 0..<4 { if reminder.isHittable { break }; app.swipeUp() }
        reminder.tap()
        XCTAssertTrue(app.navigationBars["Reminder"].waitForExistence(timeout: 5))
        let threeDays = app.buttons["reminder-three-days"]
        threeDays.tap()
        XCTAssertTrue(threeDays.isSelected)
        app.navigationBars["Reminder"].buttons["Cancel"].tap()
        XCTAssertTrue(reminder.waitForExistence(timeout: 5))
        XCTAssertTrue(reminder.label.contains("Set reminder"))
        reminder.tap()
        let selectedThreeDays = app.buttons["reminder-three-days"]
        selectedThreeDays.tap()
        XCTAssertTrue(selectedThreeDays.isSelected)
        XCTAssertTrue(app.staticTexts["Remind about"].exists)
        XCTAssertTrue(app.buttons["reminder-one-week"].exists)
        XCTAssertFalse(app.switches["reminder-notification"].exists)
        app.buttons["save-reminder"].tap()
        XCTAssertTrue(reminder.waitForExistence(timeout: 5))
        XCTAssertTrue(reminder.label.contains("Edit reminder"))
        app.navigationBars["Plant"].buttons.firstMatch.tap()
        let task = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "reminder-task-", "Snake Plant")).firstMatch
        XCTAssertTrue(task.waitForExistence(timeout: 5))
        capture("Parity saved reminder stays in Care", app)
    }

}
