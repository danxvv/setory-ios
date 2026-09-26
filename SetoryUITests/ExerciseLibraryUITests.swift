//
//  ExerciseLibraryUITests.swift
//  SetoryUITests
//
//  Exercises tab: browse/search/filter the catalog, open detail screens
//  (media, equipment, muscles, history, related exercises), and the edit
//  flow with rename persistence. `-uitest-reset` restores a pristine
//  catalog, so edits made here never leak into other tests.
//  `-uitest-offline-media` keeps media network traffic out of the tests:
//  detail screens deterministically show the thumbnail + retry state.
//

import XCTest

final class ExerciseLibraryUITests: XCTestCase {
    /// Pins the app to English so literal-string assertions hold on any simulator.
    private let englishLocaleArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Browse, search, filter, detail (library)

    func testLibraryBrowseSearchFilterAndOpenDetail() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-offline-media"] + englishLocaleArguments
        app.launch()

        openExercisesTab(app: app)

        // Alphabetical browse: the first rows of the catalog are visible.
        XCTAssertTrue(app.staticTexts["3/4 Sit-Up"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["45° Side Bend"].exists)

        // Muscle filter narrows the list; clearing restores it.
        app.buttons["filter-muscle"].tap()
        let chestOption = app.buttons["Chest"]
        XCTAssertTrue(chestOption.waitForExistence(timeout: 5))
        chestOption.tap()
        XCTAssertFalse(app.staticTexts["3/4 Sit-Up"].exists)
        app.buttons["filter-clear"].tap()
        XCTAssertTrue(app.staticTexts["3/4 Sit-Up"].waitForExistence(timeout: 5))

        // Search narrows the list (case-insensitive).
        search(app: app, text: "bench press")
        XCTAssertTrue(app.staticTexts["Barbell Bench Press"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Band Bench Press"].exists)
        XCTAssertFalse(app.staticTexts["3/4 Sit-Up"].exists)

        // No matches shows the empty state.
        app.searchFields.firstMatch.typeText("zzz")
        XCTAssertTrue(app.staticTexts["No exercises found"].waitForExistence(timeout: 5))

        // Clear back to a match and open the detail screen.
        clearSearch(app: app)
        app.searchFields.firstMatch.typeText("barbell bench press")
        let row = element(in: app, withIdentifier: "exercise-row-gv0025")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.navigationBars["Barbell Bench Press"].waitForExistence(timeout: 5))

        // Media section: offline media shows the bundled thumbnail with a
        // retry affordance, and the attribution is always visible.
        XCTAssertTrue(element(in: app, withIdentifier: "media-attribution").waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, withIdentifier: "media-retry-button").waitForExistence(timeout: 5))

        // Detail content, revealed strictly in layout order (list rows
        // don't exist in the AX tree while virtualized offscreen).
        XCTAssertTrue(element(in: app, withIdentifier: "exercise-equipment").exists)
        XCTAssertTrue(app.staticTexts["Strength"].exists)
        XCTAssertTrue(reveal(app.staticTexts["Primary muscles"], in: app))
        XCTAssertTrue(reveal(app.staticTexts["Chest"], in: app))
        XCTAssertTrue(reveal(app.staticTexts["Secondary muscles"], in: app))
        XCTAssertTrue(reveal(app.staticTexts["Triceps"], in: app))
        XCTAssertTrue(reveal(app.staticTexts["Description"], in: app))
        XCTAssertTrue(reveal(app.staticTexts["exercise-summary"], in: app))
        XCTAssertTrue(app.staticTexts["exercise-summary"].label.contains("Barbell exercise targeting the chest"))
        XCTAssertTrue(reveal(app.staticTexts["Instructions"], in: app))
        XCTAssertTrue(reveal(app.staticTexts["history-empty"], in: app))

        // Related exercises share the primary muscle and push their own detail.
        XCTAssertTrue(reveal(app.staticTexts["Related exercises"], in: app))
        let related = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH 'related-'")).firstMatch
        XCTAssertTrue(related.waitForExistence(timeout: 5))
        related.tap()
        // A new detail screen was pushed (its nav bar is not the bench press).
        XCTAssertFalse(app.navigationBars["Barbell Bench Press"].waitForExistence(timeout: 2))
    }

    func testDetailShowsSeededHistory() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-seed", "-uitest-offline-media"] + englishLocaleArguments
        app.launch()

        openDetail(app: app, searchText: "barbell bench press", rowId: "exercise-row-gv0025")

        XCTAssertTrue(reveal(app.staticTexts["Last performed"], in: app))
        XCTAssertTrue(reveal(app.staticTexts["Best set"], in: app))
        XCTAssertTrue(reveal(app.staticTexts["10 reps · 40 kg"].firstMatch, in: app))
        XCTAssertFalse(app.staticTexts["history-empty"].exists)
    }

    // MARK: - Spanish locale

    func testLibraryAndDetailRenderInSpanish() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-offline-media", "-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
        app.launch()

        let tabButton = app.tabBars.buttons["Ejercicios"]
        XCTAssertTrue(tabButton.waitForExistence(timeout: 5))
        tabButton.tap()
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 5))
        // Rows render Spanish names and sort by them, so gv0001 — which
        // leads the list in English as "3/4 Sit-Up" — is nowhere in view.
        XCTAssertFalse(app.staticTexts["3/4 Sit-Up"].exists)

        // Search spans both vocabularies: the Spanish name the user reads
        // and the canonical English one off the machine both find gv0031.
        search(app: app, text: "curl con barra")
        XCTAssertTrue(element(in: app, withIdentifier: "exercise-row-gv0031").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Curl con Barra"].exists)
        clearSearch(app: app)
        search(app: app, text: "barbell curl")
        let row = element(in: app, withIdentifier: "exercise-row-gv0031")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        // Spanish name, Spanish UI labels, Spanish per-locale content.
        XCTAssertTrue(app.navigationBars["Curl con Barra"].waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, withIdentifier: "exercise-equipment").exists)
        XCTAssertTrue(app.staticTexts["Fuerza"].exists)
        XCTAssertTrue(app.staticTexts["Músculos principales"].exists)
        XCTAssertTrue(app.staticTexts["Bíceps"].exists)
        XCTAssertTrue(reveal(app.staticTexts["Descripción"], in: app))
        XCTAssertTrue(reveal(app.staticTexts["exercise-summary"], in: app))
        XCTAssertTrue(app.staticTexts["exercise-summary"].label.contains("Ejercicio con barra"))
        XCTAssertTrue(reveal(app.staticTexts["Instrucciones"], in: app))

        XCTAssertTrue(reveal(app.staticTexts["Aún no realizado"], in: app))
        XCTAssertTrue(reveal(app.staticTexts["Ejercicios relacionados"], in: app))
    }

    // MARK: - Edit flow

    func testEditFlowRenameSavePersistsAndCancelDiscards() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-offline-media"] + englishLocaleArguments
        app.launch()

        // "bench press" (not "barbell bench press") so the still-active
        // search matches the row again after the rename to "AAA Bench Press".
        openDetail(app: app, searchText: "bench press", rowId: "exercise-row-gv0025")

        // Enter edit mode; the form is pre-filled with the displayed name.
        app.buttons["edit-exercise-button"].tap()
        let nameField = app.textFields["exercise-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        XCTAssertEqual(nameField.value as? String, "Barbell Bench Press")

        // An empty name disables Save.
        nameField.tap(withNumberOfTaps: 3, numberOfTouches: 1)
        nameField.typeText(XCUIKeyboardKey.delete.rawValue)
        XCTAssertTrue(app.staticTexts["Name is required."].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["save-exercise-button"].isEnabled)

        // Rename and save.
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

        // The exercise picker on the Log tab finds it too.
        openLogTab(app: app)
        let addExercise = app.buttons["add-exercise-button"]
        XCTAssertTrue(addExercise.waitForExistence(timeout: 5))
        addExercise.tap()
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("AAA")
        let pickerRow = element(in: app, withIdentifier: "picker-exercise-gv0025")
        XCTAssertTrue(pickerRow.waitForExistence(timeout: 5))
        pickerRow.tap()
        XCTAssertTrue(app.staticTexts["Reps"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()

        // The rename survives a relaunch (no reset this time).
        app.terminate()
        app.launchArguments = ["-uitest-offline-media"] + englishLocaleArguments
        app.launch()
        openDetail(app: app, searchText: "AAA bench", rowId: "exercise-row-gv0025")
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

    /// Swipes up until the element enters the accessibility tree (list rows
    /// don't exist while virtualized offscreen). Returns whether it appeared.
    @discardableResult
    private func reveal(_ target: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 8) -> Bool {
        var swipes = 0
        while !target.exists && swipes < maxSwipes {
            app.swipeUp()
            swipes += 1
        }
        return target.waitForExistence(timeout: 2)
    }
}
