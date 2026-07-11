//
//  WorkoutLoggingUITests.swift
//  gymappUITests
//
//  End-to-end pass over the logging flow: log strength and cardio series,
//  delete one, finish the day, relaunch, and confirm persistence and the
//  calendar highlight.
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
        app.launchArguments = ["-uitest-reset"] + englishLocaleArguments
        app.launch()

        // Empty state for today.
        XCTAssertTrue(app.staticTexts["No series yet"].waitForExistence(timeout: 5))

        // Strength series: Bench Press, 10 reps at 40 kg.
        addSeries(app: app, exercise: "Bench Press") {
            let reps = app.textFields["reps-field"]
            XCTAssertTrue(reps.waitForExistence(timeout: 5))
            reps.tap()
            reps.typeText("10")
            let weight = app.textFields["weight-field"]
            weight.tap()
            weight.typeText("40")
        }
        XCTAssertTrue(app.staticTexts["Bench Press"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["10 reps · 40 kg"].exists)

        // Cardio series: Treadmill Run, 15 minutes.
        addSeries(app: app, exercise: "Treadmill Run") {
            let duration = app.textFields["duration-field"]
            XCTAssertTrue(duration.waitForExistence(timeout: 5))
            duration.tap()
            duration.typeText("15")
        }
        XCTAssertTrue(app.staticTexts["Treadmill Run"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["15 min"].exists)

        // A third series, then swipe-to-delete it.
        addSeries(app: app, exercise: "Squat") {
            let reps = app.textFields["reps-field"]
            XCTAssertTrue(reps.waitForExistence(timeout: 5))
            reps.tap()
            reps.typeText("8")
        }
        let squatRow = app.staticTexts["Squat"]
        XCTAssertTrue(squatRow.waitForExistence(timeout: 5))
        // Clear the bottom "Finish Day" bar so the row is fully exposed,
        // then swipe the cell itself (not the text) to reveal Delete.
        app.swipeUp()
        let squatCell = app.cells.containing(.staticText, identifier: "Squat").element
        squatCell.swipeLeft(velocity: .slow)
        let deleteButton = app.buttons["Delete"]
        if deleteButton.waitForExistence(timeout: 3) {
            deleteButton.tap()
        }
        XCTAssertFalse(app.staticTexts["Squat"].waitForExistence(timeout: 2))

        // Confirm is disabled while the required field is empty.
        openExerciseMenu(app: app)
        app.buttons["Lat Pulldown"].tap()
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
        app.launchArguments = englishLocaleArguments
        app.launch()

        XCTAssertTrue(app.staticTexts["Saved workout"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Bench Press"].exists)
        XCTAssertTrue(app.staticTexts["10 reps · 40 kg"].exists)
        XCTAssertTrue(app.staticTexts["Treadmill Run"].exists)
        XCTAssertFalse(app.staticTexts["Squat"].exists)
        XCTAssertFalse(app.buttons["Finish Day"].exists)
        assertTodayHasWorkoutMarker(app: app)
    }

    private func addSeries(app: XCUIApplication, exercise: String, fill: () -> Void) {
        openExerciseMenu(app: app)
        let item = app.buttons[exercise]
        _ = item.waitForExistence(timeout: 2)
        // Long menus scroll; offscreen items are absent from the
        // accessibility tree until swiped into view.
        var swipes = 0
        while !(item.exists && item.isHittable) && swipes < 8 {
            app.swipeUp()
            swipes += 1
        }
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        item.tap()
        fill()
        let confirm = app.buttons["Confirm"]
        XCTAssertTrue(confirm.isEnabled)
        confirm.tap()
    }

    /// SwiftUI `Menu` ignores XCUITest's synthesized tap; a short press
    /// reliably opens it.
    private func openExerciseMenu(app: XCUIApplication) {
        let menuButton = app.buttons["Add Exercise"]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5))
        menuButton.press(forDuration: 0.2)
    }

    private func assertTodayHasWorkoutMarker(app: XCUIApplication) {
        let dayNumber = Calendar.current.component(.day, from: .now)
        let todayCell = app.buttons["day-\(dayNumber)"]
        XCTAssertTrue(todayCell.waitForExistence(timeout: 5))
        XCTAssertEqual(todayCell.value as? String, "workout saved")
    }
}
