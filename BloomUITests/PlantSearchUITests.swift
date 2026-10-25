import XCTest

final class PlantSearchUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    @MainActor private func capture(_ name: String, _ app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot()); attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor private func tap(_ id: String, in app: XCUIApplication) {
        let button = app.buttons[id]
        for _ in 0..<5 {
            let footer = app.buttons["reset-search-choices"]
            if button.isHittable && (!footer.exists || button.frame.maxY < footer.frame.minY - 4) { break }
            app.swipeUp()
        }
        button.tap()
    }
    @MainActor
    func testAreaPersonalizationCanBeSavedCancelledAndRemoved() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        app.buttons["home-add-plant"].tap(); app.buttons["personalize-plant-search"].tap()
        XCTAssertTrue(app.buttons["save-search-personalization"].isEnabled)
        let locate = app.buttons["search-locate-me"], cityField = app.textFields["search-growing-area"]
        XCTAssertTrue(locate.isHittable)
        XCTAssertGreaterThan(locate.frame.minX, cityField.frame.maxX)
        XCTAssertLessThan(abs(locate.frame.midY - cityField.frame.midY), 10)
        XCTAssertLessThanOrEqual(locate.frame.width, 48)
        XCTAssertFalse(app.buttons["search-climate"].exists)
        XCTAssertFalse(app.segmentedControls["search-hemisphere"].exists)
        let area = app.textFields["search-growing-area"]; area.tap(); area.typeText("Berlin\n")
        app.buttons["search-city-Berlin"].tap()
        XCTAssertTrue(app.staticTexts["Berlin"].waitForExistence(timeout: 5))
        capture("22 Native growing area preferences", app)
        tap("search-light-Lower natural light", in: app)
        tap("search-type-Bushy", in: app); tap("search-type-Trailing", in: app)
        XCTAssertEqual(app.buttons["search-type-Bushy"].value as? String, "Selected")
        XCTAssertEqual(app.buttons["search-type-Trailing"].value as? String, "Selected")
        capture("26 Native visual plant preferences", app)
        app.buttons["save-search-personalization"].tap()
        XCTAssertTrue(app.staticTexts["Seasonal picks"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Berlin ·")).firstMatch.exists)
        XCTAssertTrue(app.buttons["select-species-Pothos"].exists)
        XCTAssertTrue(app.staticTexts["Bushy · Trailing"].exists)
        capture("23 Native personalized seasonal picks", app)
        tap("select-species-Pothos", in: app)
        XCTAssertTrue(app.navigationBars["Add plant"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Epipremnum aureum")).firstMatch.exists)
        app.navigationBars["Add plant"].buttons.firstMatch.tap()
        app.buttons["personalize-plant-search"].tap()
        XCTAssertTrue(app.staticTexts["Berlin"].exists)
        app.buttons["change-search-location"].tap()
        app.textFields["search-growing-area"].tap(); app.textFields["search-growing-area"].typeText("London")
        XCTAssertFalse(app.buttons["save-search-personalization"].isEnabled)
        app.navigationBars["Your growing space"].buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Berlin ·")).firstMatch.exists)
        app.buttons["personalize-plant-search"].tap()
        tap("reset-plant-personalization", in: app)
        XCTAssertTrue(app.staticTexts["Choose a plant"].waitForExistence(timeout: 5))
    }
    @MainActor
    func testResetChoicesKeepsCityAndCancelRestoresSavedPreferences() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--uitesting-search-location"]; app.launch()
        app.buttons["home-add-plant"].tap(); app.buttons["personalize-plant-search"].tap()
        tap("search-light-Lower natural light", in: app)
        tap("search-type-Bushy", in: app); tap("search-type-Trailing", in: app)
        app.buttons["save-search-personalization"].tap()
        app.buttons["personalize-plant-search"].tap()
        let reset = app.buttons["reset-search-choices"]
        XCTAssertTrue(reset.isHittable)
        capture("26 Native visual plant preferences", app)
        reset.tap()
        XCTAssertTrue(reset.isHittable)
        XCTAssertFalse(reset.isEnabled)
        XCTAssertEqual(app.buttons["search-light-Not sure yet"].value as? String, "Selected")
        XCTAssertEqual(app.buttons["search-type-Bushy"].value as? String, "Not selected")
        XCTAssertEqual(app.buttons["search-type-Trailing"].value as? String, "Not selected")
        capture("22 Native growing area preferences", app)
        capture("28 Native compact preference reset", app)
        app.navigationBars["Your growing space"].buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["Bushy · Trailing"].exists)
        app.buttons["personalize-plant-search"].tap()
        XCTAssertEqual(app.buttons["search-light-Lower natural light"].value as? String, "Selected")
        app.buttons["reset-search-choices"].tap()
        app.buttons["save-search-personalization"].tap()
        XCTAssertFalse(app.staticTexts["Bushy · Trailing"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Berlin ·")).firstMatch.exists)
    }
    @MainActor
    func testLocateMeDenialKeepsSavedCityAndManualSearchAvailable() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--uitesting-search-location"]; app.launch()
        app.buttons["home-add-plant"].tap(); app.buttons["personalize-plant-search"].tap()
        app.buttons["search-locate-me"].tap()
        XCTAssertTrue(app.staticTexts["search-location-status"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Berlin"].exists)
        app.buttons["change-search-location"].tap()
        XCTAssertTrue(app.textFields["search-growing-area"].exists)
        capture("27 Native location access fallback", app)
        app.buttons["Keep current location"].tap(); app.buttons["save-search-personalization"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Berlin ·")).firstMatch.waitForExistence(timeout: 5))
    }
    @MainActor
    func testLocateMeSuccessStillSavesWhenClimateIsUnavailable() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting", "--uitesting-location-success", "--uitesting-climate-unavailable"]; app.launch()
        app.buttons["home-add-plant"].tap(); app.buttons["personalize-plant-search"].tap()
        app.buttons["search-locate-me"].tap()
        XCTAssertTrue(app.staticTexts["Berlin"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Retry seasonal context"].exists)
        XCTAssertTrue(app.buttons["save-search-personalization"].isEnabled)
        app.buttons["save-search-personalization"].tap()
        XCTAssertTrue(app.staticTexts["Seasonal picks"].waitForExistence(timeout: 5))
    }
    @MainActor
    func testAliasSearchOwnershipAndRecentSearches() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        app.buttons["home-add-plant"].tap()
        let field = app.textFields["plant-search-field"]; field.tap(); field.typeText("Swiss cheese\n")
        let result = app.buttons["select-species-Monstera"]
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        XCTAssertTrue(result.label.contains("2 in My plants"))
        result.tap()
        XCTAssertTrue(app.navigationBars["Add plant"].waitForExistence(timeout: 5))
        app.navigationBars["Add plant"].buttons.firstMatch.tap()
        app.buttons["plant-search-clear"].tap()
        XCTAssertTrue(app.buttons["recent-search-Swiss cheese"].waitForExistence(timeout: 5))
        capture("24 Native recent plant searches", app)
        app.buttons["recent-search-Swiss cheese"].tap()
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        app.buttons["plant-search-clear"].tap()
        app.buttons["clear-recent-searches"].tap()
        XCTAssertFalse(app.buttons["recent-search-Swiss cheese"].exists)
        app.navigationBars["Add plant"].buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["My plants (5)"].waitForExistence(timeout: 5))
    }
    @MainActor
    func testUnlistedPlantCanStillCompleteSetup() {
        let app = XCUIApplication(); app.launchArguments = ["--uitesting"]; app.launch()
        app.buttons["home-add-plant"].tap()
        let field = app.textFields["plant-search-field"]; field.tap(); field.typeText("Fern\n")
        XCTAssertTrue(app.staticTexts["No catalog match yet"].waitForExistence(timeout: 5))
        capture("25 Native unlisted plant search", app)
        app.buttons["add-custom-search"].tap()
        app.buttons["overlay-continue-plant"].tap()
        app.buttons["Choose later"].tap()
        app.buttons["setup-status-Looking good"].tap()
        app.buttons["overlay-save-plant"].tap()
        XCTAssertTrue(app.navigationBars["Plant"].waitForExistence(timeout: 5))
        app.navigationBars["Plant"].buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["My plants (6)"].waitForExistence(timeout: 5))
    }
}
