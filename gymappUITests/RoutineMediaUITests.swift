//
//  RoutineMediaUITests.swift
//  gymappUITests
//
//  Routine media on the logging screen: plan, draft, and saved-session
//  rows show exercise thumbnails whose tap opens the media viewer sheet
//  without triggering the row's primary action. `-uitest-offline-media`
//  keeps the network out, so the viewer must degrade to the bundled
//  thumbnail with a retry affordance and no error alert.
//

import XCTest

final class RoutineMediaUITests: XCTestCase {
    /// Pins the app to English so literal-string assertions hold on any simulator.
    private let englishLocaleArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// 4.1: plan rows show thumbnails; the thumbnail opens the viewer (not
    /// the set-entry popup) and the row tap still opens the popup.
    func testPlanRowThumbnailOpensViewerAndRowStillLogsSets() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-offline-media"] + englishLocaleArguments
        app.launch()

        // A reset wipes templates, so create one to apply.
        openTab(app: app, name: "Routines")
        app.buttons["create-template-button"].tap()
        let nameField = app.textFields["template-name-field"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Media Day")
        addExercise(app: app, search: "bench press", pickerIdentifier: "picker-exercise-gv0025")
        XCTAssertTrue(app.staticTexts["Barbell Bench Press"].waitForExistence(timeout: 5))
        app.buttons["save-template-button"].tap()

        // Apply it to today on the Log tab.
        openTab(app: app, name: "Log")
        let startButton = app.buttons["start-from-template-button"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()
        let templateChoice = element(in: app, withIdentifier: "apply-template-Media Day")
        XCTAssertTrue(templateChoice.waitForExistence(timeout: 5))
        templateChoice.tap()
        XCTAssertTrue(app.staticTexts["Plan: Media Day"].waitForExistence(timeout: 5))

        // The plan row shows the exercise thumbnail.
        let thumbnail = element(in: app, withIdentifier: "routine-thumbnail-gv0025")
        XCTAssertTrue(thumbnail.waitForExistence(timeout: 5))

        // Tapping the thumbnail opens the media viewer, not the popup.
        thumbnail.tap()
        let viewer = element(in: app, withIdentifier: "routine-media-gv0025")
        XCTAssertTrue(viewer.waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["Barbell Bench Press"].exists)
        XCTAssertFalse(app.textFields["reps-field"].exists)

        let doneButton = app.buttons["routine-media-done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 5))
        doneButton.tap()
        XCTAssertFalse(viewer.waitForExistence(timeout: 2))

        // Tapping the row elsewhere still opens the set-entry popup.
        app.staticTexts["Barbell Bench Press"].tap()
        let reps = app.textFields["reps-field"]
        XCTAssertTrue(reps.waitForExistence(timeout: 5))
        XCTAssertFalse(element(in: app, withIdentifier: "routine-media-gv0025").exists)
        app.buttons["Cancel"].tap()
    }

    /// 4.2: draft and saved-session rows show thumbnails; offline, the
    /// viewer degrades to the bundled thumbnail with a retry affordance
    /// and no error alert. Swipe-to-delete on draft rows keeps working.
    func testSeriesRowThumbnailsAndOfflineDegradation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-offline-media"] + englishLocaleArguments
        app.launch()

        // Draft row: log one bench press set through the picker.
        XCTAssertTrue(app.staticTexts["No series yet"].waitForExistence(timeout: 5))
        app.buttons["add-exercise-button"].tap()
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText("barbell bench press")
        let pickerRow = element(in: app, withIdentifier: "picker-exercise-gv0025")
        XCTAssertTrue(pickerRow.waitForExistence(timeout: 5))
        pickerRow.tap()
        let reps = app.textFields["reps-field"]
        XCTAssertTrue(reps.waitForExistence(timeout: 5))
        reps.tap()
        reps.typeText("10")
        app.buttons["Confirm"].tap()

        // The draft row shows the thumbnail; tapping it opens the viewer,
        // which degrades offline: bundled thumbnail + retry, no alert.
        let draftThumbnail = element(in: app, withIdentifier: "routine-thumbnail-gv0025")
        XCTAssertTrue(draftThumbnail.waitForExistence(timeout: 5))
        draftThumbnail.tap()
        XCTAssertTrue(element(in: app, withIdentifier: "routine-media-gv0025").waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, withIdentifier: "media-retry-button").waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, withIdentifier: "media-attribution").exists)
        XCTAssertEqual(app.alerts.count, 0)
        app.buttons["routine-media-done"].tap()
        XCTAssertFalse(element(in: app, withIdentifier: "routine-media-gv0025").waitForExistence(timeout: 2))

        // Swipe-to-delete on the draft row still works with the thumbnail.
        let draftCell = app.cells.containing(.staticText, identifier: "Barbell Bench Press").element
        draftCell.swipeLeft(velocity: .slow)
        let deleteButton = app.buttons["Delete"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 3))
        deleteButton.tap()
        XCTAssertFalse(app.staticTexts["Barbell Bench Press"].waitForExistence(timeout: 2))

        // Saved-session rows: relaunch with the seeded session for today
        // (Barbell Bench Press + Run).
        app.terminate()
        app.launchArguments = ["-uitest-reset", "-uitest-seed", "-uitest-offline-media"] + englishLocaleArguments
        app.launch()
        XCTAssertTrue(app.staticTexts["Saved workout"].waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, withIdentifier: "routine-thumbnail-gv0025").waitForExistence(timeout: 5))
        let runThumbnail = element(in: app, withIdentifier: "routine-thumbnail-gv0685")
        XCTAssertTrue(runThumbnail.exists)

        // The viewer opens for the exercise whose thumbnail was tapped.
        runThumbnail.tap()
        XCTAssertTrue(element(in: app, withIdentifier: "routine-media-gv0685").waitForExistence(timeout: 5))
        XCTAssertTrue(app.navigationBars["Run"].exists)
        XCTAssertEqual(app.alerts.count, 0)
        app.buttons["routine-media-done"].tap()
    }

    // MARK: - Helpers

    /// Adds one exercise inside the template editor's picker sheet.
    private func addExercise(app: XCUIApplication, search: String, pickerIdentifier: String) {
        let addButton = app.buttons["add-exercises-button"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
        addButton.tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText(search)

        let row = element(in: app, withIdentifier: pickerIdentifier)
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        // While search is active the sheet hides its navigation bar; the
        // bottom search bar's close button (localized label) restores it.
        let closeSearch = app.buttons.matching(
            NSPredicate(format: "label ==[c] 'close' OR label ==[c] 'cerrar'")
        ).firstMatch
        if closeSearch.waitForExistence(timeout: 2) {
            closeSearch.tap()
        }

        let confirm = app.buttons["add-selected-exercises-button"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
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

    /// SwiftUI moves a row's accessibility identifier between the cell and
    /// its inner button depending on OS version; match any element type.
    private func element(in app: XCUIApplication, withIdentifier id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }
}
