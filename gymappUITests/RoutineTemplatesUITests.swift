//
//  RoutineTemplatesUITests.swift
//  gymappUITests
//
//  Routine templates end to end: create a template on the Routines tab,
//  apply it on the Log tab, log a planned set, finish the day, and confirm
//  only logged series were saved. Plus save-as-template pre-fill/cancel and
//  the duplicate / delete-with-confirmation flows.
//

import XCTest

final class RoutineTemplatesUITests: XCTestCase {
    /// Pins the app to English so literal-string assertions hold on any simulator.
    private let englishLocaleArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCreateTemplateApplyItAndFinishDaySavesOnlyLoggedSeries() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"] + englishLocaleArguments
        app.launch()

        // Both sections start empty after a reset.
        openRoutinesTab(app: app)
        XCTAssertTrue(app.staticTexts["No templates yet"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["No routines yet"].exists)

        // Create "Push Day" with Bench Press and Squat. The name is typed
        // before picking exercises, so the suggested name must not touch it.
        app.buttons["create-template-button"].tap()
        let nameField = app.textFields["template-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Push Day")

        addExercises(app: app, searches: [("bench press", "picker-exercise-gv0025"),
                                          ("full squat", "picker-exercise-gv0043")])

        XCTAssertTrue(app.staticTexts["Barbell Bench Press"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Barbell Full Squat"].exists)
        XCTAssertEqual(nameField.value as? String, "Push Day",
                       "adding exercises must never overwrite a typed name")

        let saveButton = app.buttons["save-template-button"]
        XCTAssertTrue(saveButton.isEnabled)
        saveButton.tap()

        // The new template row shows name, exercise count, and muscle chips.
        XCTAssertTrue(app.staticTexts["Push Day"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["2 exercises"].exists)
        XCTAssertTrue(app.staticTexts["Chest"].exists)
        XCTAssertTrue(app.staticTexts["Glutes"].exists)

        // Apply it to today on the Log tab.
        openTab(app: app, name: "Log")
        let startButton = app.buttons["start-from-template-button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()
        let templateChoice = app.descendants(matching: .any)
            .matching(identifier: "apply-template-Push Day").firstMatch
        XCTAssertTrue(templateChoice.waitForExistence(timeout: 5))
        templateChoice.tap()

        // The plan stages both exercises at 0/3 (default target).
        XCTAssertTrue(app.staticTexts["Plan: Push Day"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Barbell Bench Press"].exists)
        XCTAssertTrue(app.staticTexts["Barbell Full Squat"].exists)
        XCTAssertEqual(app.staticTexts.matching(identifier: "0/3 sets").count, 2)

        // Log one bench press set from the plan row.
        app.cells.containing(.staticText, identifier: "Barbell Bench Press").element(boundBy: 0).tap()
        let reps = app.textFields["reps-field"]
        XCTAssertTrue(reps.waitForExistence(timeout: 5))
        reps.tap()
        reps.typeText("10")
        let weight = app.textFields["weight-field"]
        weight.tap()
        weight.typeText("40")
        app.buttons["Confirm"].tap()

        // Progress advances and the set appears in the day's series list.
        XCTAssertTrue(app.staticTexts["1/3 sets"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["0/3 sets"].exists)
        XCTAssertTrue(app.staticTexts["10 reps · 40 kg"].exists)

        // Finish the day: only the logged series is persisted; the squat
        // target was never met and must not produce placeholder series.
        let finishButton = app.buttons["Finish Day"]
        if !finishButton.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(finishButton.waitForExistence(timeout: 5))
        finishButton.tap()

        XCTAssertTrue(app.staticTexts["Saved workout"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Plan: Push Day"].exists)
        XCTAssertTrue(app.staticTexts["Barbell Bench Press"].exists)
        XCTAssertFalse(app.staticTexts["Barbell Full Squat"].exists)

        let detailLink = app.staticTexts["View routine details"]
        XCTAssertTrue(detailLink.waitForExistence(timeout: 5))
        if !detailLink.isHittable {
            app.swipeUp()
        }
        detailLink.tap()
        XCTAssertTrue(app.staticTexts["10 reps · 40 kg"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1"].exists)
        XCTAssertFalse(app.staticTexts["Barbell Full Squat"].exists)
    }

    func testSaveSessionAsTemplatePrefillsEditorAndCancelCreatesNothing() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-seed"] + englishLocaleArguments
        app.launch()

        // Open the seeded session (Bench Press + Treadmill Run).
        openRoutinesTab(app: app)
        let sessionRow = app.staticTexts["Barbell Bench Press, Run"]
        XCTAssertTrue(sessionRow.waitForExistence(timeout: 5))
        sessionRow.tap()

        let saveAsTemplate = app.buttons["save-as-template-button"]
        XCTAssertTrue(saveAsTemplate.waitForExistence(timeout: 5))
        saveAsTemplate.tap()

        // Editor is pre-filled: suggested name from chest + full body, both
        // exercises in session order with 1 set each (one series apiece).
        let nameField = app.textFields["template-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        XCTAssertEqual(nameField.value as? String, "Chest & Full Body")
        XCTAssertTrue(app.staticTexts["Barbell Bench Press"].exists)
        XCTAssertTrue(app.staticTexts["Run"].exists)
        XCTAssertEqual(app.staticTexts.matching(identifier: "1 set").count, 2)

        // Cancelling persists nothing.
        app.buttons["cancel-template-button"].tap()
        app.navigationBars.buttons.firstMatch.tap() // back to the Routines list
        XCTAssertTrue(app.staticTexts["No templates yet"].waitForExistence(timeout: 5))
    }

    func testDuplicateAndDeleteTemplateFlows() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"] + englishLocaleArguments
        app.launch()

        // Create a template without typing a name: the suggestion ("Leg
        // Day" for a squat-only list) fills the field and is saved as-is.
        openRoutinesTab(app: app)
        app.buttons["create-template-button"].tap()
        XCTAssertTrue(app.textFields["template-name-field"].waitForExistence(timeout: 5))
        addExercises(app: app, searches: [("full squat", "picker-exercise-gv0043")])
        XCTAssertEqual(app.textFields["template-name-field"].value as? String, "Leg Day")
        app.buttons["save-template-button"].tap()
        XCTAssertTrue(app.staticTexts["Leg Day"].waitForExistence(timeout: 5))

        // Duplicate via the row's context menu.
        app.cells.containing(.staticText, identifier: "Leg Day").element(boundBy: 0).press(forDuration: 1.0)
        let duplicateAction = app.buttons["Duplicate"]
        XCTAssertTrue(duplicateAction.waitForExistence(timeout: 5))
        duplicateAction.tap()
        XCTAssertTrue(app.staticTexts["Leg Day copy"].waitForExistence(timeout: 5))

        // Swipe-delete the copy; deletion requires confirmation.
        let copyCell = app.cells.containing(.staticText, identifier: "Leg Day copy").element
        copyCell.swipeLeft(velocity: .slow)
        let rowDelete = app.buttons["Delete"]
        XCTAssertTrue(rowDelete.waitForExistence(timeout: 3))
        rowDelete.tap()

        XCTAssertTrue(app.staticTexts["Delete this template?"].waitForExistence(timeout: 5))
        let confirmDelete = app.sheets.buttons["Delete"].exists
            ? app.sheets.buttons["Delete"]
            : app.buttons["Delete"]
        confirmDelete.tap()

        XCTAssertFalse(app.staticTexts["Leg Day copy"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.staticTexts["Leg Day"].exists)

        // Templates persist across relaunch (no reset flag this time).
        app.terminate()
        app.launchArguments = ["-uitest-disable-animations"] + englishLocaleArguments
        app.launch()
        openRoutinesTab(app: app)
        XCTAssertTrue(app.staticTexts["Leg Day"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Leg Day copy"].exists)
    }

    /// Spanish walkthrough: suggested names, section headers, muscle chips,
    /// and the plural set-count formats must all render localized.
    func testSpanishLocalizedTemplateFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
        app.launch()

        openTab(app: app, name: "Rutinas")
        XCTAssertTrue(app.staticTexts["Plantillas"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Aún no hay plantillas"].exists)
        XCTAssertTrue(app.staticTexts["Historial"].exists)

        // A squat-only template suggests the localized "Leg Day".
        app.buttons["create-template-button"].tap()
        XCTAssertTrue(app.textFields["template-name-field"].waitForExistence(timeout: 5))
        addExercises(app: app, searches: [("full squat", "picker-exercise-gv0043")])
        XCTAssertTrue(app.staticTexts["Barbell Full Squat"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["template-name-field"].value as? String, "Día de pierna")
        XCTAssertTrue(app.staticTexts["3 series"].exists)
        attachScreenshot(app: app, name: "es-editor")
        app.buttons["save-template-button"].tap()

        // Row shows localized count and muscle chips ("Glúteos" — the
        // dataset squat's primary muscle).
        XCTAssertTrue(app.staticTexts["Día de pierna"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 ejercicio"].exists)
        XCTAssertTrue(app.staticTexts["Glúteos"].exists)
        attachScreenshot(app: app, name: "es-routines-list")

        // Apply on the Log tab: localized plan header and set progress.
        openTab(app: app, name: "Registro")
        let startButton = app.buttons["start-from-template-button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()
        let templateChoice = app.descendants(matching: .any)
            .matching(identifier: "apply-template-Día de pierna").firstMatch
        XCTAssertTrue(templateChoice.waitForExistence(timeout: 5))
        templateChoice.tap()

        XCTAssertTrue(app.staticTexts["Plan: Día de pierna"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["0/3 series"].exists)
        attachScreenshot(app: app, name: "es-log-plan")
    }

    // MARK: - Helpers

    /// Opens the "Add Exercises" picker once per entry, searches, selects
    /// the exercise, and confirms with Add.
    private func addExercises(app: XCUIApplication, searches: [(query: String, identifier: String)]) {
        for (query, identifier) in searches {
            let addButton = app.buttons["add-exercises-button"]
            XCTAssertTrue(addButton.waitForExistence(timeout: 5))
            addButton.tap()

            let searchField = app.searchFields.firstMatch
            if !searchField.waitForExistence(timeout: 3) {
                app.swipeDown()
            }
            XCTAssertTrue(searchField.waitForExistence(timeout: 5))
            searchField.tap()
            searchField.typeText(query)

            let row = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
            XCTAssertTrue(row.waitForExistence(timeout: 5))
            row.tap()

            // While search is active the sheet hides its navigation bar
            // (and with it Cancel/Add); the bottom search bar's close
            // button restores it. Selections survive leaving search. The
            // button exposes only a localized label ('close' / 'cerrar').
            let closeSearch = app.buttons.matching(
                NSPredicate(format: "label ==[c] 'close' OR label ==[c] 'cerrar'")
            ).firstMatch
            if closeSearch.waitForExistence(timeout: 2) {
                closeSearch.tap()
            }

            let confirm = app.buttons["add-selected-exercises-button"]
            XCTAssertTrue(confirm.waitForExistence(timeout: 5))
            XCTAssertTrue(confirm.isEnabled)
            confirm.tap()
        }
    }

    private func openRoutinesTab(app: XCUIApplication) {
        openTab(app: app, name: "Routines")
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
