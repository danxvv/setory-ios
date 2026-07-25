//
//  PhotoMatchUITests.swift
//  gymappUITests
//
//  Photo exercise-match flows against the -uitest-photo-match stub (no
//  network): the success path from the template editor into a saved
//  template, the error path's alert with retry, and the no-key path's
//  pointer to AI Settings. The sheet's test-only fixture button stands in
//  for the camera and the system photo picker, so no system UI is touched.
//

import XCTest

final class PhotoMatchUITests: XCTestCase {
    /// Pins the app to English so literal-string assertions hold on any simulator.
    private let englishLocaleArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Success scenario

    func testPhotoMatchAddsSelectedExerciseToTemplateDraft() throws {
        let app = launch(scenario: "success")
        openTemplateEditor(app: app)

        // Named before matching: adding exercises auto-fills the name field
        // while it is still empty, which would swallow a later typed name.
        let nameField = app.textFields["template-name-field"]
        nameField.tap()
        nameField.typeText("Photo Day")

        // The entry point sits beside the regular picker in the exercises
        // section and opens straight into the capture phase.
        app.buttons["photo-match-button"].tap()
        let findButton = app.buttons["photo-match-find-button"]
        XCTAssertTrue(findButton.waitForExistence(timeout: 5))
        XCTAssertFalse(findButton.isEnabled, "sending needs at least one photo")

        // Camera is unavailable in the Simulator, so only the library and
        // fixture paths are offered.
        XCTAssertFalse(app.buttons["photo-match-camera-button"].exists)

        app.buttons["photo-match-attach-fixture-button"].tap()
        XCTAssertTrue(findButton.isEnabled)
        attachScreenshot(app: app, name: "photo-match-capture")

        findButton.tap()

        // The stub answers after a short delay with two known catalog ids.
        let benchResult = element(app, "photo-match-result-gv0025")
        XCTAssertTrue(benchResult.waitForExistence(timeout: 10))
        XCTAssertTrue(element(app, "photo-match-result-gv0043").exists)
        XCTAssertTrue(app.staticTexts["Barbell Bench Press"].exists)
        XCTAssertTrue(app.staticTexts["High match"].exists)
        // Muscle chips come from the local record, not the model.
        XCTAssertTrue(app.staticTexts["Chest"].exists)
        attachScreenshot(app: app, name: "photo-match-results")

        // Confirming with nothing selected is not allowed.
        let addButton = app.buttons["photo-match-add-button"]
        XCTAssertTrue(addButton.exists)
        XCTAssertFalse(addButton.isEnabled)

        benchResult.tap()
        XCTAssertTrue(addButton.isEnabled)
        addButton.tap()

        // The match lands in the draft as a normal item with the default
        // target set count; only the selected one was added.
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Barbell Bench Press"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Barbell Full Squat"].exists)
        XCTAssertTrue(app.staticTexts["3 sets"].exists)
        XCTAssertEqual(nameField.value as? String, "Photo Day",
                       "adding matched exercises must never overwrite a typed name")

        app.buttons["save-template-button"].tap()

        // The saved draft is a standard template in the Routines list.
        XCTAssertTrue(app.staticTexts["Photo Day"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 exercise"].exists)
    }

    /// Dismissing from the results phase must leave the draft untouched.
    func testDismissingResultsAddsNothingToTheDraft() throws {
        let app = launch(scenario: "success")
        openTemplateEditor(app: app)

        app.buttons["photo-match-button"].tap()
        XCTAssertTrue(app.buttons["photo-match-attach-fixture-button"].waitForExistence(timeout: 5))
        app.buttons["photo-match-attach-fixture-button"].tap()
        app.buttons["photo-match-find-button"].tap()

        XCTAssertTrue(element(app, "photo-match-result-gv0025").waitForExistence(timeout: 10))
        app.buttons["photo-match-cancel-button"].tap()

        XCTAssertTrue(app.textFields["template-name-field"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Barbell Bench Press"].exists)
        XCTAssertFalse(app.buttons["save-template-button"].isEnabled)
    }

    // MARK: - Description and main-muscle hints

    /// The hints are optional context the user attaches before sending. The
    /// stub answers the same either way — that the muscle actually narrows
    /// the catalog is asserted against the serialized body in
    /// `PhotoMatchRequestBuilderTests`.
    func testDescriptionAndMainMuscleHintsReachTheResults() throws {
        let app = launch(scenario: "success")
        openTemplateEditor(app: app)

        app.buttons["photo-match-button"].tap()
        XCTAssertTrue(app.buttons["photo-match-attach-fixture-button"].waitForExistence(timeout: 5))
        app.buttons["photo-match-attach-fixture-button"].tap()

        // Unset by default: neither hint is required to send.
        let muscleMenu = element(app, "photo-match-muscle-menu")
        XCTAssertTrue(muscleMenu.label.contains("Any muscle"))

        selectMuscle(app: app, named: "Chest")
        XCTAssertTrue(muscleMenu.label.contains("Chest"))

        let descriptionField = app.textFields["photo-match-description-field"]
        XCTAssertTrue(descriptionField.exists)
        descriptionField.tap()
        // Trailing newline dismisses the keyboard so the send button is hittable.
        descriptionField.typeText("seat pushes forward, handles at chest height\n")
        attachScreenshot(app: app, name: "photo-match-hints")

        app.buttons["photo-match-find-button"].tap()

        XCTAssertTrue(element(app, "photo-match-result-gv0025").waitForExistence(timeout: 10))
    }

    /// A failed match returns to capture with everything the user typed
    /// still there — retrying must not mean re-entering the hints.
    func testHintsSurviveAFailedMatch() throws {
        let app = launch(scenario: "error")
        openTemplateEditor(app: app)

        app.buttons["photo-match-button"].tap()
        XCTAssertTrue(app.buttons["photo-match-attach-fixture-button"].waitForExistence(timeout: 5))
        app.buttons["photo-match-attach-fixture-button"].tap()

        selectMuscle(app: app, named: "Chest")
        let descriptionField = app.textFields["photo-match-description-field"]
        descriptionField.tap()
        descriptionField.typeText("cable stack\n")

        app.buttons["photo-match-find-button"].tap()

        let alert = app.alerts["Photo match failed"]
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        alert.buttons["Cancel"].tap()

        XCTAssertTrue(app.buttons["photo-match-find-button"].waitForExistence(timeout: 5))
        XCTAssertEqual(descriptionField.value as? String, "cable stack")
        XCTAssertTrue(element(app, "photo-match-muscle-menu").label.contains("Chest"))
    }

    /// Obliques is in the muscle list but no catalog exercise lists it as a
    /// primary target, so the narrowed catalog would be empty — which would
    /// ship an empty schema enum and be rejected by OpenRouter.
    func testMainMuscleWithNoExercisesBlocksTheRequest() throws {
        let app = launch(scenario: "success")
        openTemplateEditor(app: app)

        app.buttons["photo-match-button"].tap()
        XCTAssertTrue(app.buttons["photo-match-attach-fixture-button"].waitForExistence(timeout: 5))
        app.buttons["photo-match-attach-fixture-button"].tap()

        let findButton = app.buttons["photo-match-find-button"]
        XCTAssertTrue(findButton.isEnabled)

        selectMuscle(app: app, named: "Obliques")

        XCTAssertTrue(element(app, "photo-match-empty-muscle-note").waitForExistence(timeout: 5))
        XCTAssertFalse(findButton.isEnabled, "an empty catalog must never be sent")
        attachScreenshot(app: app, name: "photo-match-empty-muscle")

        // Clearing the selection unblocks sending; no request ever went out.
        selectMuscle(app: app, named: "Any muscle")
        XCTAssertTrue(findButton.isEnabled)
        XCTAssertFalse(element(app, "photo-match-empty-muscle-note").exists)
        XCTAssertFalse(element(app, "photo-match-result-gv0025").exists)
    }

    // MARK: - Error scenario

    func testPhotoMatchErrorShowsLocalizedAlertWithRetry() throws {
        let app = launch(scenario: "error")
        openTemplateEditor(app: app)

        app.buttons["photo-match-button"].tap()
        XCTAssertTrue(app.buttons["photo-match-attach-fixture-button"].waitForExistence(timeout: 5))
        app.buttons["photo-match-attach-fixture-button"].tap()
        app.buttons["photo-match-find-button"].tap()

        let alert = app.alerts["Photo match failed"]
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        XCTAssertTrue(alert.staticTexts["Couldn't reach OpenRouter. Check your connection and try again."].exists)
        attachScreenshot(app: app, name: "photo-match-error")

        // Retry resends the already-attached photo — no re-picking.
        let retryButton = alert.buttons["Retry"]
        XCTAssertTrue(retryButton.exists)
        retryButton.tap()
        XCTAssertTrue(alert.waitForExistence(timeout: 10))
        alert.buttons["Cancel"].tap()

        // Dismissing returns to the capture phase with the photo still attached.
        let findButton = app.buttons["photo-match-find-button"]
        XCTAssertTrue(findButton.waitForExistence(timeout: 5))
        XCTAssertTrue(findButton.isEnabled)
    }

    // MARK: - No-key scenario

    func testWithoutKeyPhotoMatchPointsToAISettings() throws {
        let app = launch(scenario: "no-key")
        openTemplateEditor(app: app)

        app.buttons["photo-match-button"].tap()

        // No capture affordances at all until a key exists.
        XCTAssertTrue(element(app, "photo-match-key-required-text").waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["photo-match-find-button"].exists)
        XCTAssertFalse(app.buttons["photo-match-attach-fixture-button"].exists)

        // The deep link into settings unlocks the flow in-session.
        app.buttons["photo-match-open-settings-button"].tap()
        let keyField = app.secureTextFields["ai-api-key-field"]
        XCTAssertTrue(keyField.waitForExistence(timeout: 5))
        keyField.tap()
        keyField.typeText("sk-or-v1-uitest")
        app.buttons["ai-save-key-button"].tap()
        XCTAssertTrue(element(app, "ai-key-configured-label").waitForExistence(timeout: 5))
        app.buttons["ai-settings-done-button"].tap()

        XCTAssertTrue(app.buttons["photo-match-find-button"].waitForExistence(timeout: 5))
        XCTAssertFalse(element(app, "photo-match-key-required-text").exists)
    }

    // MARK: - Helpers

    private func launch(scenario: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-photo-match", scenario] + englishLocaleArguments
        app.launch()
        return app
    }

    private func openTemplateEditor(app: XCUIApplication) {
        openTab(app: app, name: "Routines")
        let createButton = app.buttons["create-template-button"]
        XCTAssertTrue(createButton.waitForExistence(timeout: 5))
        createButton.tap()
        XCTAssertTrue(app.textFields["template-name-field"].waitForExistence(timeout: 5))
    }

    /// Opens the main-muscle menu and picks an entry. The muscle list is
    /// long enough that later entries start offscreen, which a swipe fixes.
    private func selectMuscle(app: XCUIApplication, named name: String) {
        element(app, "photo-match-muscle-menu").tap()
        let option = app.buttons[name]
        if !option.waitForExistence(timeout: 2) {
            app.swipeUp()
        }
        XCTAssertTrue(option.waitForExistence(timeout: 5), "muscle '\(name)' not in the menu")
        option.tap()
    }

    /// Identifier-first lookup that tolerates SwiftUI exposing rows as
    /// cells, static texts, or other elements.
    private func element(_ app: XCUIApplication, _ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Kept even on success so localized rendering can be inspected from
    /// the xcresult bundle.
    private func attachScreenshot(app: XCUIApplication, name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
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
