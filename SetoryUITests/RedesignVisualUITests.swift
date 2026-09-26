import XCTest

/// Screenshots complement the behavior suite with the redesigned surfaces,
/// including the Log tab and keyboard layouts that the catalog smoke test omits.
final class RedesignVisualUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMainScreensSpanish() {
        let app = launch(seeded: true)
        XCTAssertTrue(app.staticTexts["Entrenamiento guardado"].waitForExistence(timeout: 10))
        attach(app, "01-log-saved")

        app.tabBars.buttons["Ejercicios"].tap()
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 5))
        attach(app, "02-library")

        app.tabBars.buttons["Rutinas"].tap()
        XCTAssertTrue(app.buttons["create-template-button"].waitForExistence(timeout: 5))
        attach(app, "03-routines")

        app.buttons["create-template-button"].tap()
        XCTAssertTrue(app.textFields["template-name-field"].waitForExistence(timeout: 5))
        attach(app, "04-template-editor")
        app.buttons["cancel-template-button"].tap()

        app.buttons["ai-settings-button"].tap()
        XCTAssertTrue(app.secureTextFields["ai-api-key-field"].waitForExistence(timeout: 5))
        attach(app, "05-settings")
        app.buttons["ai-settings-done-button"].tap()

        app.tabBars.buttons["Progreso"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["overview-chart"].waitForExistence(timeout: 5))
        attach(app, "06-progress")
    }

    func testEmptyLogAndSetEntrySpanish() {
        let app = launch(seeded: false)
        let add = app.buttons["add-exercise-button"]
        XCTAssertTrue(add.waitForExistence(timeout: 10))
        XCTAssertTrue(add.isHittable)
        attach(app, "07-log-empty")
        add.tap()

        let search = app.searchFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("barbell bench press")
        let exercise = app.descendants(matching: .any)["picker-exercise-gv0025"].firstMatch
        XCTAssertTrue(exercise.waitForExistence(timeout: 5))
        exercise.tap()

        let reps = app.textFields["reps-field"]
        XCTAssertTrue(reps.waitForExistence(timeout: 5))
        reps.tap()
        reps.typeText("10")
        let weight = app.textFields["weight-field"]
        XCTAssertTrue(weight.isHittable)
        weight.tap()
        weight.typeText("40")
        attach(app, "08-set-entry-keyboard")
    }

    func testLargeTextNavigationSpanish() {
        let app = launch(seeded: false, largeText: true)
        let add = app.buttons["add-exercise-button"]
        XCTAssertTrue(app.tabBars.buttons["Registro"].waitForExistence(timeout: 10))
        attach(app, "09a-large-text-calendar")
        for _ in 0..<5 {
            if add.exists && add.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(add.isHittable)
        attach(app, "09-large-text-log")

        app.tabBars.buttons["Ejercicios"].tap()
        XCTAssertTrue(app.buttons["filter-muscle"].waitForExistence(timeout: 5))
        attach(app, "10-large-text-library")

        app.tabBars.buttons["Rutinas"].tap()
        XCTAssertTrue(app.buttons["create-template-button"].waitForExistence(timeout: 5))
        attach(app, "11-large-text-routines")
    }

    private func launch(seeded: Bool, largeText: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest-reset", "-uitest-offline-media", "-uitest-ai", "success",
                               "-AppleLanguages", "(es)", "-AppleLocale", "es_MX"]
        if seeded { app.launchArguments.append("-uitest-seed") }
        if largeText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
        return app
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
