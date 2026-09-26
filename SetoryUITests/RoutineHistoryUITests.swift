//
//  RoutineHistoryUITests.swift
//  SetoryUITests
//
//  Routines tab: empty state, seeded list rows, detail navigation, and the
//  logging screen's saved-workout entry point into the same detail view.
//  `-uitest-seed` inserts two sessions: today (Barbell Bench Press, Run)
//  and three days earlier (Barbell Full Squat).
//

import XCTest

final class RoutineHistoryUITests: XCTestCase {
    /// Pins the app to English so literal-string assertions hold on any simulator.
    private let englishLocaleArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testRoutinesTabShowsEmptyStateAfterReset() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"] + englishLocaleArguments
        app.launch()

        openRoutinesTab(app: app)

        XCTAssertTrue(app.staticTexts["No routines yet"].waitForExistence(timeout: 5))
    }

    func testRoutinesListShowsSeededSessionsAndOpensDetail() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-seed"] + englishLocaleArguments
        app.launch()

        openRoutinesTab(app: app)

        // Both seeded sessions appear with their summaries, newest first.
        // (The History section sits below the Templates section, so rows
        // are found by content, and recency by vertical position.)
        XCTAssertTrue(app.staticTexts["Barbell Bench Press, Run"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Barbell Full Squat"].exists)
        XCTAssertTrue(app.staticTexts["2 series"].exists)
        XCTAssertTrue(app.staticTexts["1 series"].exists)
        let newestRow = app.cells.containing(.staticText, identifier: "Barbell Bench Press, Run").element
        let olderRow = app.cells.containing(.staticText, identifier: "Barbell Full Squat").element
        XCTAssertTrue(newestRow.exists)
        XCTAssertTrue(newestRow.frame.minY < olderRow.frame.minY)

        // Tapping the newest row pushes the detail: muscles-worked summary,
        // series values, and per-row primary muscles.
        newestRow.tap()
        XCTAssertTrue(app.staticTexts["Muscles worked"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Chest · Full Body"].exists)
        XCTAssertTrue(app.staticTexts["Barbell Bench Press"].exists)
        XCTAssertTrue(app.staticTexts["10 reps · 40 kg"].exists)
        XCTAssertTrue(app.staticTexts["Run"].exists)
        XCTAssertTrue(app.staticTexts["15 min"].exists)
        XCTAssertTrue(app.staticTexts["Chest"].exists)
        XCTAssertTrue(app.staticTexts["Full Body"].exists)
    }

    func testLogTabSavedDayOpensRoutineDetail() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-seed"] + englishLocaleArguments
        app.launch()

        // Today is selected by default; re-tap its cell to mirror the
        // select-a-saved-day flow.
        let dayNumber = Calendar.current.component(.day, from: .now)
        let todayCell = app.buttons["day-\(dayNumber)"]
        XCTAssertTrue(todayCell.waitForExistence(timeout: 5))
        todayCell.tap()

        XCTAssertTrue(app.staticTexts["Saved workout"].waitForExistence(timeout: 5))

        let detailLink = app.staticTexts["View routine details"]
        XCTAssertTrue(detailLink.waitForExistence(timeout: 5))
        if !detailLink.isHittable {
            app.swipeUp()
        }
        detailLink.tap()

        XCTAssertTrue(app.staticTexts["Muscles worked"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Chest · Full Body"].exists)
        XCTAssertTrue(app.staticTexts["10 reps · 40 kg"].exists)
        XCTAssertTrue(app.staticTexts["15 min"].exists)
    }

    /// The tab bar exposes its buttons under `tabBars` on most OS versions;
    /// fall back to a plain button query if the hierarchy differs.
    private func openRoutinesTab(app: XCUIApplication) {
        let tabButton = app.tabBars.buttons["Routines"]
        if tabButton.waitForExistence(timeout: 5) {
            tabButton.tap()
        } else {
            let fallback = app.buttons["Routines"]
            XCTAssertTrue(fallback.waitForExistence(timeout: 5))
            fallback.tap()
        }
    }
}
