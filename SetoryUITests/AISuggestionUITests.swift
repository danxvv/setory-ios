//
//  AISuggestionUITests.swift
//  SetoryUITests
//
//  AI suggestion flows against the -uitest-ai stub (no network): settings
//  key save/clear unlocking the suggest entry point, the success path into
//  a pre-filled template editor, and the error path's alert with retry.
//

import XCTest

final class AISuggestionUITests: XCTestCase {
    /// Pins the app to English so literal-string assertions hold on any simulator.
    private let englishLocaleArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Settings gate (task 4.3 + no-key scenario)

    func testSavingAndClearingKeyTogglesSuggestAvailability() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-ai", "no-key"] + englishLocaleArguments
        app.launch()
        openTab(app: app, name: "Routines")

        // Without a key the suggest action explains itself; no goal field,
        // no editor, no network.
        app.buttons["suggest-with-ai-button"].tap()
        let keyRequired = element(app, "suggest-key-required-text")
        XCTAssertTrue(keyRequired.waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["suggest-goal-field"].exists)
        XCTAssertFalse(app.buttons["suggest-generate-button"].exists)
        XCTAssertFalse(app.textFields["template-name-field"].exists)

        // Deep link into settings and save a key (in-memory store).
        app.buttons["suggest-open-settings-button"].tap()
        let keyField = app.secureTextFields["ai-api-key-field"]
        XCTAssertTrue(keyField.waitForExistence(timeout: 5))
        keyField.tap()
        keyField.typeText("sk-or-v1-uitest")
        app.buttons["ai-save-key-button"].tap()
        XCTAssertTrue(element(app, "ai-key-configured-label").waitForExistence(timeout: 5))
        app.buttons["ai-settings-done-button"].tap()

        // Back on the suggest sheet, the flow is unlocked.
        XCTAssertTrue(app.textFields["suggest-goal-field"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["suggest-generate-button"].exists)
        XCTAssertFalse(keyRequired.exists)

        // Clear the key from the toolbar settings sheet.
        app.buttons["suggest-dismiss-button"].tap()
        let settingsButton = app.buttons["ai-settings-button"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()
        let clearButton = app.buttons["ai-clear-key-button"]
        XCTAssertTrue(clearButton.waitForExistence(timeout: 5))
        clearButton.tap()
        XCTAssertFalse(element(app, "ai-key-configured-label").exists)
        app.buttons["ai-settings-done-button"].tap()

        // The suggest action is back in its key-required state.
        app.buttons["suggest-with-ai-button"].tap()
        XCTAssertTrue(element(app, "suggest-key-required-text").waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["suggest-generate-button"].exists)
    }

    // MARK: - Success scenario (task 6.1)

    func testSuggestSuccessPrefillsEditorAndSavesTemplate() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-ai", "success"] + englishLocaleArguments
        app.launch()
        openTab(app: app, name: "Routines")

        app.buttons["suggest-with-ai-button"].tap()
        let goalField = app.textFields["suggest-goal-field"]
        XCTAssertTrue(goalField.waitForExistence(timeout: 5))
        goalField.tap()
        goalField.typeText("full body, 45 minutes")
        app.buttons["suggest-generate-button"].tap()

        // The stub answers after a short delay; the editor opens pre-filled
        // with the suggested name, rationale, exercises, and target sets.
        let nameField = app.textFields["template-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))
        XCTAssertEqual(nameField.value as? String, "AI Full Body")
        XCTAssertTrue(element(app, "suggestion-rationale").exists)
        XCTAssertTrue(app.staticTexts["Barbell Bench Press"].exists)
        XCTAssertTrue(app.staticTexts["Barbell Full Squat"].exists)
        XCTAssertTrue(app.staticTexts["4 sets"].exists)
        XCTAssertTrue(app.staticTexts["3 sets"].exists)
        // Muscle coverage derives from the local records of the suggested
        // exercises (bench press → chest, full squat → glutes).
        XCTAssertTrue(app.staticTexts["Chest"].exists)
        XCTAssertTrue(app.staticTexts["Glutes"].exists)

        app.buttons["save-template-button"].tap()

        // The saved suggestion is a standard template in the Routines list.
        XCTAssertTrue(app.staticTexts["AI Full Body"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["2 exercises"].exists)
    }

    // MARK: - Error scenario (task 6.1)

    func testSuggestErrorShowsLocalizedAlertWithRetry() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-ai", "error"] + englishLocaleArguments
        app.launch()
        openTab(app: app, name: "Routines")

        app.buttons["suggest-with-ai-button"].tap()
        let generateButton = app.buttons["suggest-generate-button"]
        XCTAssertTrue(generateButton.waitForExistence(timeout: 5))
        generateButton.tap()

        // The stubbed network failure surfaces as a localized alert with
        // a retry action.
        let alert = app.alerts["Suggestion failed"]
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        XCTAssertTrue(alert.staticTexts["Couldn't reach OpenRouter. Check your connection and try again."].exists)
        let retryButton = alert.buttons["Retry"]
        XCTAssertTrue(retryButton.exists)

        // Retry runs the request again and fails the same way.
        retryButton.tap()
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        alert.buttons["Cancel"].tap()

        // Dismissing the alert returns to the sheet; no editor appeared.
        XCTAssertTrue(generateButton.waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["template-name-field"].exists)
    }

    // MARK: - Helpers

    /// Identifier-first lookup that tolerates SwiftUI exposing rows as
    /// cells, static texts, or other elements.
    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// The tab bar exposes its buttons under `tabBars` on most OS versions;
    /// fall back to a plain button query if the hierarchy differs.
    private func openTab(app: XCUIApplication, name: String) {
        let tabButton = app.tabBars.buttons[name]
        if tabButton.waitForExistence(timeout: 5) {
            tabButton.tap()
        } else {
            let fallback = app.buttons[name]
            XCTAssertTrue(fallback.waitForExistence(timeout: 5))
            fallback.tap()
        }
    }
}
