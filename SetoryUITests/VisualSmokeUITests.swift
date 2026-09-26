//
//  VisualSmokeUITests.swift
//  SetoryUITests
//
//  Captures keepAlways screenshots of the catalog surfaces (library grid
//  with thumbnails, detail media section, Spanish content, AI suggestion
//  sheet) so a headless run can be verified visually via
//  `xcresulttool export attachments`. Assertions are minimal on purpose.
//

import XCTest

final class VisualSmokeUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCatalogSurfacesEnglish() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-offline-media", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        app.tabBars.buttons["Exercises"].tap()
        XCTAssertTrue(app.staticTexts["3/4 Sit-Up"].waitForExistence(timeout: 5))
        attach(app: app, name: "en-library")

        let field = app.searchFields.firstMatch
        field.tap()
        field.typeText("barbell bench press")
        let row = app.descendants(matching: .any).matching(identifier: "exercise-row-gv0025").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.navigationBars["Barbell Bench Press"].waitForExistence(timeout: 5))
        attach(app: app, name: "en-detail-media")

        app.tabBars.buttons["Log"].tap()
        app.buttons["add-exercise-button"].tap()
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 5))
        attach(app: app, name: "en-picker")
    }

    func testCatalogSurfacesSpanish() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-offline-media", "-uitest-ai", "success", "-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
        app.launch()

        app.tabBars.buttons["Ejercicios"].tap()
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        // A canonical English query on a Spanish device: search spans both
        // vocabularies, so the English name off the machine still finds the
        // row even though the row itself reads Spanish.
        field.typeText("barbell curl")
        let row = app.descendants(matching: .any).matching(identifier: "exercise-row-gv0031").firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Curl con Barra"].waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.navigationBars["Curl con Barra"].waitForExistence(timeout: 5))
        app.swipeUp()
        attach(app: app, name: "es-detail-content")

        // AI suggestion sheet in Spanish (stubbed service, no network).
        app.tabBars.buttons["Rutinas"].tap()
        let suggest = app.buttons["suggest-with-ai-button"]
        XCTAssertTrue(suggest.waitForExistence(timeout: 5))
        suggest.tap()
        XCTAssertTrue(app.textFields["suggest-goal-field"].waitForExistence(timeout: 5))
        attach(app: app, name: "es-ai-sheet")
        app.buttons["suggest-generate-button"].tap()
        XCTAssertTrue(app.textFields["template-name-field"].waitForExistence(timeout: 10))
        attach(app: app, name: "es-ai-editor")
    }

    private func attach(app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
