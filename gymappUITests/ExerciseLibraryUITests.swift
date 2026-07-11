//
//  ExerciseLibraryUITests.swift
//  gymappUITests
//
//  Exercises tab: browse/search the catalog, open detail screens (content,
//  muscles, history, related exercises), and the edit flow with rename
//  persistence. `-uitest-reset` restores a pristine catalog, so edits made
//  here never leak into other tests.
//

import XCTest

final class ExerciseLibraryUITests: XCTestCase {
    /// Pins the app to English so literal-string assertions hold on any simulator.
    private let englishLocaleArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Browse, search, detail (library)

    func testLibraryBrowseSearchAndOpenDetail() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"] + englishLocaleArguments
        app.launch()

        openExercisesTab(app: app)

        // Alphabetical browse: the first rows of the catalog are visible.
        XCTAssertTrue(app.staticTexts["Back Extension"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Barbell Curl"].exists)

        // Search narrows the list (case-insensitive).
        search(app: app, text: "bench")
        XCTAssertTrue(app.staticTexts["Bench Press"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Incline Bench Press"].exists)
        XCTAssertFalse(app.staticTexts["Back Extension"].exists)

        // No matches shows the empty state.
        app.searchFields.firstMatch.typeText("zzz")
        XCTAssertTrue(app.staticTexts["No exercises found"].waitForExistence(timeout: 5))

        // Clear back to a match and open the detail screen.
        clearSearch(app: app)
        app.searchFields.firstMatch.typeText("bench press")
        let row = element(in: app, withIdentifier: "exercise-row-bench-press")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        // Detail content: description, instructions, muscles, empty history.
        XCTAssertTrue(app.staticTexts["Description"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["exercise-summary"].label.contains("classic barbell press"))
        XCTAssertTrue(app.staticTexts["Strength"].exists)
        XCTAssertTrue(app.staticTexts["Primary muscles"].exists)
        XCTAssertTrue(app.staticTexts["Chest"].exists)
        XCTAssertTrue(app.staticTexts["Secondary muscles"].exists)
        XCTAssertTrue(app.staticTexts["Triceps"].exists)
        XCTAssertTrue(app.staticTexts["Instructions"].exists)

        app.swipeUp()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["history-empty"].exists)

        // Related exercises share the primary muscle and push their own detail.
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Related exercises"].waitForExistence(timeout: 5))
        let related = element(in: app, withIdentifier: "related-cable-crossover")
        XCTAssertTrue(related.waitForExistence(timeout: 5))
        related.tap()
        XCTAssertTrue(app.navigationBars["Cable Crossover"].waitForExistence(timeout: 5))
    }

    func testDetailShowsSeededHistory() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-seed"] + englishLocaleArguments
        app.launch()

        openDetail(app: app, searchText: "bench press", rowId: "exercise-row-bench-press")

        app.swipeUp()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Last performed"].exists)
        XCTAssertTrue(app.staticTexts["Best set"].exists)
        XCTAssertTrue(app.staticTexts["10 reps · 40 kg"].firstMatch.exists)
        XCTAssertFalse(app.staticTexts["history-empty"].exists)
    }

    // MARK: - Spanish locale

    func testLibraryAndDetailRenderInSpanish() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
        app.launch()

        // Tab label and library content are Spanish.
        let tabButton = app.tabBars.buttons["Ejercicios"]
        XCTAssertTrue(tabButton.waitForExistence(timeout: 5))
        tabButton.tap()
        XCTAssertTrue(app.staticTexts["Curl con barra"].waitForExistence(timeout: 5))

        // Locale-independent identifiers reach the detail screen.
        search(app: app, text: "press de banca")
        let row = element(in: app, withIdentifier: "exercise-row-bench-press")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        XCTAssertTrue(app.navigationBars["Press de banca"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Descripción"].exists)
        XCTAssertTrue(app.staticTexts["Fuerza"].exists)
        XCTAssertTrue(app.staticTexts["Músculos principales"].exists)
        XCTAssertTrue(app.staticTexts["Pecho"].exists)
        XCTAssertTrue(app.staticTexts["Instrucciones"].exists)
        XCTAssertTrue(app.staticTexts["exercise-summary"].label.contains("press clásico con barra"))

        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Historial"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Aún no realizado"].exists)
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Ejercicios relacionados"].waitForExistence(timeout: 5))
    }

    // MARK: - Edit flow

    func testEditFlowRenameSavePersistsAndCancelDiscards() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"] + englishLocaleArguments
        app.launch()

        openDetail(app: app, searchText: "bench press", rowId: "exercise-row-bench-press")

        // Enter edit mode; the form is pre-filled with the displayed name.
        app.buttons["edit-exercise-button"].tap()
        let nameField = app.textFields["exercise-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        XCTAssertEqual(nameField.value as? String, "Bench Press")

        // An empty name disables Save.
        nameField.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        nameField.typeText(XCUIKeyboardKey.delete.rawValue)
        XCTAssertTrue(app.staticTexts["Name is required."].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["save-exercise-button"].isEnabled)

        // Rename ("AAA" prefix keeps it at the top of alphabetical lists,
        // so the Add Exercise menu shows it without scrolling) and save.
        nameField.typeText("AAA Bench Press")
        XCTAssertTrue(app.buttons["save-exercise-button"].isEnabled)
        app.buttons["save-exercise-button"].tap()

        // Back on the detail screen with the user's name.
        XCTAssertTrue(app.navigationBars["AAA Bench Press"].waitForExistence(timeout: 5))

        // Cancel discards: start another edit, mangle the name, cancel.
        app.buttons["edit-exercise-button"].tap()
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        nameField.typeText("Discarded Name")
        app.buttons["cancel-edit-button"].tap()
        XCTAssertTrue(app.navigationBars["AAA Bench Press"].waitForExistence(timeout: 5))

        // The library list shows the new name.
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["AAA Bench Press"].waitForExistence(timeout: 5))

        // The Add Exercise menu on the Log tab shows it too.
        openLogTab(app: app)
        let addExercise = app.buttons["Add Exercise"]
        XCTAssertTrue(addExercise.waitForExistence(timeout: 5))
        addExercise.press(forDuration: 0.2)
        XCTAssertTrue(app.buttons["AAA Bench Press"].waitForExistence(timeout: 5))
        app.buttons["AAA Bench Press"].tap()
        XCTAssertTrue(app.staticTexts["Reps"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()

        // The rename survives a relaunch (no reset this time).
        app.terminate()
        app.launchArguments = englishLocaleArguments
        app.launch()
        openDetail(app: app, searchText: "AAA bench", rowId: "exercise-row-bench-press")
        XCTAssertTrue(app.navigationBars["AAA Bench Press"].waitForExistence(timeout: 5))
    }

    // MARK: - Helpers

    private func openExercisesTab(app: XCUIApplication) {
        let tabButton = app.tabBars.buttons["Exercises"]
        if tabButton.waitForExistence(timeout: 5) {
            tabButton.tap()
        } else {
            let fallback = app.buttons["Exercises"]
            XCTAssertTrue(fallback.waitForExistence(timeout: 5))
            fallback.tap()
        }
    }

    private func openLogTab(app: XCUIApplication) {
        let tabButton = app.tabBars.buttons["Log"]
        if tabButton.waitForExistence(timeout: 5) {
            tabButton.tap()
        } else {
            app.buttons["Log"].tap()
        }
    }

    private func search(app: XCUIApplication, text: String) {
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(text)
    }

    private func clearSearch(app: XCUIApplication) {
        let field = app.searchFields.firstMatch
        let clearButton = field.buttons.firstMatch
        if clearButton.exists {
            clearButton.tap()
            field.tap()
        } else {
            field.tap(withNumberOfTaps: 3, numberOfTouches: 1)
            field.typeText(XCUIKeyboardKey.delete.rawValue)
        }
    }

    private func openDetail(app: XCUIApplication, searchText: String, rowId: String) {
        openExercisesTab(app: app)
        search(app: app, text: searchText)
        let row = element(in: app, withIdentifier: rowId)
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
    }

    /// SwiftUI moves a row's accessibility identifier between the cell and
    /// its inner button depending on OS version; match any element type.
    private func element(in app: XCUIApplication, withIdentifier id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }
}
