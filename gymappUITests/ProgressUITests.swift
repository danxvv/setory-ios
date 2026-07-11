//
//  ProgressUITests.swift
//  gymappUITests
//
//  Progress tab: empty state, seeded overview + muscle balance, navigation
//  to the progression chart from both the Progress list and the exercise
//  detail screen. `-uitest-seed` inserts two sessions: today (Bench Press
//  10×40, Treadmill Run 15 min) and three days earlier (Squat 8×70).
//

import XCTest

final class ProgressUITests: XCTestCase {
    /// Pins the app to English so literal-string assertions hold on any simulator.
    private let englishLocaleArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testProgressTabShowsEmptyStateAfterReset() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset"] + englishLocaleArguments
        app.launch()

        openProgressTab(app: app)

        XCTAssertTrue(app.staticTexts["No progress yet"].waitForExistence(timeout: 5))
    }

    func testSeededSessionsPopulateOverviewAndMuscleBalance() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-seed"] + englishLocaleArguments
        app.launch()

        openProgressTab(app: app)

        // Overview: chart plus headline counts. Exact numbers depend on the
        // weekday the suite runs on (the squat session lies 3 days back),
        // so assert presence, not values.
        XCTAssertTrue(element(in: app, withIdentifier: "overview-chart").waitForExistence(timeout: 5))
        XCTAssertTrue(reveal(element(in: app, withIdentifier: "headline-week"), in: app))
        XCTAssertTrue(reveal(element(in: app, withIdentifier: "headline-month"), in: app))

        // Muscle balance (Week): today's seeded session always contributes
        // Bench Press → chest and Treadmill Run → full body.
        XCTAssertTrue(reveal(element(in: app, withIdentifier: "balance-chest"), in: app))
        XCTAssertTrue(reveal(element(in: app, withIdentifier: "balance-full_body"), in: app))
    }

    func testProgressionListNavigatesToChart() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-seed"] + englishLocaleArguments
        app.launch()

        openProgressTab(app: app)

        // Searching collapses the screen to the performed-exercise list.
        search(app: app, text: "bench press")
        let benchRow = element(in: app, withIdentifier: "progression-row-bench-press")
        XCTAssertTrue(benchRow.waitForExistence(timeout: 5))
        benchRow.tap()

        // Weighted strength: best set, metric chart, and volume chart.
        let bestSet = element(in: app, withIdentifier: "progression-best")
        XCTAssertTrue(bestSet.waitForExistence(timeout: 5))
        XCTAssertTrue(combinedText(of: bestSet).contains("40 kg"))
        XCTAssertTrue(element(in: app, withIdentifier: "progression-chart").exists)
        XCTAssertTrue(reveal(element(in: app, withIdentifier: "progression-volume-chart"), in: app))
    }

    func testDetailHistoryLinksToProgression() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-seed"] + englishLocaleArguments
        app.launch()

        openExercisesTab(app: app)
        search(app: app, text: "bench press")
        let row = element(in: app, withIdentifier: "exercise-row-bench-press")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        let link = element(in: app, withIdentifier: "exercise-progression-link")
        XCTAssertTrue(reveal(link, in: app))
        link.tap()

        XCTAssertTrue(element(in: app, withIdentifier: "progression-chart").waitForExistence(timeout: 5))
        let bestSet = element(in: app, withIdentifier: "progression-best")
        XCTAssertTrue(bestSet.exists)
        XCTAssertTrue(combinedText(of: bestSet).contains("40 kg"))
    }

    /// Localization spec: the Progress screens render Spanish on a Spanish
    /// device. Also attaches screenshots so chart rendering can be inspected.
    func testProgressTabShowsSpanishUI() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-seed", "-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
        app.launch()

        openTab(named: "Progreso", app: app)

        XCTAssertTrue(app.navigationBars["Progreso"].waitForExistence(timeout: 5))
        XCTAssertTrue(element(in: app, withIdentifier: "overview-chart").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Resumen"].exists)
        attachScreenshot(named: "progress-tab-es")

        XCTAssertTrue(reveal(app.staticTexts["Balance muscular"], in: app))
        XCTAssertTrue(reveal(app.staticTexts["Progresión de ejercicios"], in: app))

        let benchRow = element(in: app, withIdentifier: "progression-row-bench-press")
        XCTAssertTrue(reveal(benchRow, in: app))
        benchRow.tap()

        XCTAssertTrue(element(in: app, withIdentifier: "progression-chart").waitForExistence(timeout: 5))
        let bestSet = element(in: app, withIdentifier: "progression-best")
        XCTAssertTrue(bestSet.exists)
        XCTAssertTrue(combinedText(of: bestSet).contains("Mejor serie"))
        attachScreenshot(named: "progression-screen-es")
    }

    func testUnperformedExerciseHasNoProgressionLink() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-seed"] + englishLocaleArguments
        app.launch()

        openExercisesTab(app: app)
        search(app: app, text: "deadlift")
        let row = element(in: app, withIdentifier: "exercise-row-deadlift")
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()

        XCTAssertTrue(reveal(app.staticTexts["Not performed yet"], in: app))
        XCTAssertFalse(element(in: app, withIdentifier: "exercise-progression-link").exists)
    }

    // MARK: - Helpers

    private func openProgressTab(app: XCUIApplication) {
        openTab(named: "Progress", app: app)
    }

    private func openExercisesTab(app: XCUIApplication) {
        openTab(named: "Exercises", app: app)
    }

    /// The tab bar exposes its buttons under `tabBars` on most OS versions;
    /// fall back to a plain button query if the hierarchy differs.
    private func openTab(named name: String, app: XCUIApplication) {
        let tabButton = app.tabBars.buttons[name]
        if tabButton.waitForExistence(timeout: 5) {
            tabButton.tap()
        } else {
            let fallback = app.buttons[name]
            XCTAssertTrue(fallback.waitForExistence(timeout: 5))
            fallback.tap()
        }
    }

    private func search(app: XCUIApplication, text: String) {
        let field = app.searchFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.typeText(text)
    }

    /// SwiftUI moves a row's accessibility identifier between the cell and
    /// its inner button depending on OS version; match any element type.
    private func element(in app: XCUIApplication, withIdentifier id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    /// LabeledContent exposes one combined accessibility element whose value
    /// string may land in `label` or `value` depending on OS version.
    private func combinedText(of element: XCUIElement) -> String {
        "\(element.label) \((element.value as? String) ?? "")"
    }

    private func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Offscreen list content doesn't exist in the accessibility tree until
    /// scrolled into view; swipe up until the element appears and is
    /// actually tappable (not tucked under the tab bar).
    @discardableResult
    private func reveal(_ target: XCUIElement, in app: XCUIApplication, maxSwipes: Int = 4) -> Bool {
        for _ in 0..<maxSwipes {
            if target.exists && target.isHittable {
                return true
            }
            app.swipeUp()
        }
        return target.exists
    }
}
