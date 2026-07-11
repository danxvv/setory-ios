//
//  LocalizationTests.swift
//  gymappTests
//
//  Guards catalog completeness: every bundled exercise id must have a
//  Spanish display name in the compiled ExerciseNames table and Spanish
//  summary/step entries in the ExerciseContent table, so adding an exercise
//  to exercises.json without translating it fails the suite.
//

import Foundation
import Testing
@testable import gymapp

struct LocalizationTests {
    private let missing = "‹missing›"

    private func spanishBundle() throws -> Bundle {
        let esPath = try #require(Bundle.main.path(forResource: "es", ofType: "lproj"))
        return try #require(Bundle(path: esPath))
    }

    @Test func everyBundledExerciseHasSpanishDisplayName() throws {
        let entries = try BundledCatalogSource().loadCatalog()
        #expect(!entries.isEmpty)
        let esBundle = try spanishBundle()

        for entry in entries {
            let localized = esBundle.localizedString(
                forKey: "exercise.\(entry.id)",
                value: missing,
                table: "ExerciseNames"
            )
            #expect(
                localized != missing,
                "Exercise id '\(entry.id)' has no Spanish display name in ExerciseNames.xcstrings"
            )
        }
    }

    /// Every user-facing string added by the routine-templates feature must
    /// have a Spanish value in the compiled Localizable table. Plural keys
    /// ("%lld sets", "%lld exercises", "%lld/%lld sets") live in the
    /// stringsdict and are exercised by the UI tests instead.
    @Test func everyRoutineTemplateKeyHasSpanishValue() throws {
        let newKeys = [
            "Templates", "New Template", "Edit Template",
            "No templates yet", "Create a template to plan your workouts.",
            "Duplicate", "Delete", "Delete this template?",
            "This won't affect saved workouts.", "%@ copy",
            "Add", "Add Exercises", "Add at least one exercise.",
            "Save as template", "Start from template",
            "Plan: %@", "Replace current plan?", "Replace",
            "Your logged series will be kept.", "Last: %@",
            "Leg Day", "%@ & %@",
        ]
        let esBundle = try spanishBundle()

        for key in newKeys {
            let localized = esBundle.localizedString(forKey: key, value: missing, table: nil)
            #expect(
                localized != missing,
                "Key '\(key)' has no Spanish value in Localizable.xcstrings"
            )
        }
    }

    @Test func everyBundledExerciseHasSpanishContent() throws {
        let entries = try BundledCatalogSource().loadCatalog()
        #expect(!entries.isEmpty)
        let esBundle = try spanishBundle()

        for entry in entries {
            let summary = esBundle.localizedString(
                forKey: "exercise.\(entry.id).summary",
                value: missing,
                table: "ExerciseContent"
            )
            #expect(
                summary != missing,
                "Exercise id '\(entry.id)' has no Spanish summary in ExerciseContent.xcstrings"
            )
            for index in 1...entry.instructions.count {
                let step = esBundle.localizedString(
                    forKey: "exercise.\(entry.id).step.\(index)",
                    value: missing,
                    table: "ExerciseContent"
                )
                #expect(
                    step != missing,
                    "Exercise id '\(entry.id)' has no Spanish step \(index) in ExerciseContent.xcstrings"
                )
            }
        }
    }
}
