//
//  WorkoutLoggingUITests.swift
//  SetoryUITests
//
//  End-to-end pass over the logging flow: log strength and cardio series
//  through the searchable picker sheet, delete one, finish the day,
//  relaunch, and confirm persistence and the calendar highlight.
//

import XCTest

final class WorkoutLoggingUITests: XCTestCase {
    /// Pins the app to English so literal-string assertions hold on any simulator.
    private let englishLocaleArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLogWorkoutEndToEnd() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-offline-media"] + englishLocaleArguments
        app.launch()

        // Empty state for today.
        XCTAssertTrue(app.staticTexts["No series yet"].waitForExistence(timeout: 5))

        // Strength series: Barbell Bench Press, 10 reps at 40 kg.
        addSeries(app: app, search: "barbell bench press", exerciseId: "gv0025") {
            let reps = app.textFields["reps-field"]
            XCTAssertTrue(reps.waitForExistence(timeout: 5))
            reps.tap()
            reps.typeText("10")
            let weight = app.textFields["weight-field"]
            weight.tap()
            weight.typeText("40")
        }
        XCTAssertTrue(app.staticTexts["Barbell Bench Press"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["10 reps · 40 kg"].exists)

        // Cardio series. "Walk Elliptical Cross Trainer" is the only name
        // matching "elliptical cross", so its row is never virtualized
        // offscreen (searching "run" matches dozens of names — even
        // "Trunk Rotation" contains it).
        addSeries(app: app, search: "elliptical cross", exerciseId: "gv2141") {
            let duration = app.textFields["duration-field"]
            XCTAssertTrue(duration.waitForExistence(timeout: 5))
            duration.tap()
            duration.typeText("15")
        }
        XCTAssertTrue(app.staticTexts["Walk Elliptical Cross Trainer"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["15 min"].exists)

        // A third series, then swipe-to-delete it.
        addSeries(app: app, search: "barbell full squat", exerciseId: "gv0043") {
            let reps = app.textFields["reps-field"]
            XCTAssertTrue(reps.waitForExistence(timeout: 5))
            reps.tap()
            reps.typeText("8")
        }
        let squatRow = app.staticTexts["Barbell Full Squat"]
        XCTAssertTrue(app.reveal(squatRow))
        // Clear the bottom "Finish Day" bar so the row is fully exposed,
        // then swipe the cell itself (not the text) to reveal Delete.
        app.swipeUp()
        let squatCell = app.cells.containing(.staticText, identifier: "Barbell Full Squat").element
        squatCell.swipeLeft(velocity: .slow)
        let deleteButton = app.buttons["Delete"]
        if deleteButton.waitForExistence(timeout: 3) {
            deleteButton.tap()
        }
        XCTAssertFalse(app.staticTexts["Barbell Full Squat"].waitForExistence(timeout: 2))

        // Confirm is disabled while the required field is empty.
        pickExercise(app: app, search: "cable pulldown", exerciseId: "gv0198")
        let confirm = app.buttons["Confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        XCTAssertFalse(confirm.isEnabled)
        app.buttons["Cancel"].tap()

        // Finish the day.
        let finishButton = app.buttons["Finish Day"]
        XCTAssertTrue(finishButton.waitForExistence(timeout: 5))
        finishButton.tap()

        // Saved state: read-only list, no Finish Day, calendar highlight.
        XCTAssertTrue(app.staticTexts["Saved workout"].waitForExistence(timeout: 5))
        XCTAssertFalse(finishButton.exists)
        assertTodayHasWorkoutMarker(app: app)

        // Relaunch without the reset flag: the session must persist.
        app.terminate()
        app.launchArguments = ["-uitest-disable-animations"] + englishLocaleArguments
        app.launch()

        XCTAssertTrue(app.staticTexts["Saved workout"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Barbell Bench Press"].exists)
        XCTAssertTrue(app.staticTexts["10 reps · 40 kg"].exists)
        XCTAssertTrue(app.staticTexts["Walk Elliptical Cross Trainer"].exists)
        XCTAssertFalse(app.staticTexts["Barbell Full Squat"].exists)
        XCTAssertFalse(app.buttons["Finish Day"].exists)
        assertTodayHasWorkoutMarker(app: app)
    }

    func testPickerFiltersByEquipment() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-offline-media"] + englishLocaleArguments
        app.launch()

        let addButton = app.buttons["add-exercise-button"]
        XCTAssertTrue(app.reveal(addButton, swipingUp: false))
        addButton.tap()

        // Filter to kettlebell: a barbell exercise disappears from the list.
        let equipmentFilter = app.buttons["filter-equipment"]
        XCTAssertTrue(equipmentFilter.waitForExistence(timeout: 5))
        equipmentFilter.tap()
        let kettlebellOption = app.buttons["Kettlebell"]
        XCTAssertTrue(kettlebellOption.waitForExistence(timeout: 5))
        kettlebellOption.tap()

        // First kettlebell exercise by name ("Kettlebell Advanced Windmill")
        // is visible; the barbell bench press is filtered out.
        XCTAssertTrue(element(in: app, withIdentifier: "picker-exercise-gv0517").waitForExistence(timeout: 5))
        XCTAssertFalse(element(in: app, withIdentifier: "picker-exercise-gv0025").exists)

        // Clearing the filter restores the full list ("3/4 Sit-Up" first).
        app.buttons["filter-clear"].tap()
        XCTAssertTrue(element(in: app, withIdentifier: "picker-exercise-gv0001").waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
    }

    // MARK: - Helpers

    /// Opens the picker sheet, searches, and taps the exercise row.
    private func pickExercise(app: XCUIApplication, search: String, exerciseId: String) {
        let addButton = app.buttons["add-exercise-button"]
        XCTAssertTrue(app.reveal(addButton, swipingUp: false))
        addButton.tap()

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))
        searchField.tap()
        searchField.typeText(search)

        let row = element(in: app, withIdentifier: "picker-exercise-\(exerciseId)")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
    }

    private func addSeries(app: XCUIApplication, search: String, exerciseId: String, fill: () -> Void) {
        pickExercise(app: app, search: search, exerciseId: exerciseId)
        fill()
        let confirm = app.buttons["Confirm"]
        XCTAssertTrue(confirm.isEnabled)
        confirm.tap()
    }

    private func assertTodayHasWorkoutMarker(app: XCUIApplication) {
        let dayNumber = Calendar.current.component(.day, from: .now)
        let todayCell = app.buttons["day-\(dayNumber)"]
        XCTAssertTrue(app.reveal(todayCell, swipingUp: false))
        XCTAssertEqual(todayCell.value as? String, "workout saved")
    }

    /// SwiftUI moves a row's accessibility identifier between the cell and
    /// its inner button depending on OS version; match any element type.
    private func element(in app: XCUIApplication, withIdentifier id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }
}
