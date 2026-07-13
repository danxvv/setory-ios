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

    /// Every user-facing string added by the AI suggestion feature must
    /// have a Spanish value in the compiled Localizable table.
    @Test func everyAISuggestionKeyHasSpanishValue() throws {
        let newKeys = [
            "AI Settings", "Done", "API Key", "API key configured",
            "OpenRouter API Key", "Save Key", "Clear Key",
            "Stored securely in the Keychain and never shown again after saving. Saving replaces the previous key.",
            "Model", "Model ID", "Leave empty to use the default: %@", "Privacy",
            "When you request a suggestion, your exercise IDs, set counts, muscle data, session dates, and optional goal are sent to OpenRouter under your API key. Requests happen only when you ask for a suggestion.",
            "Suggest with AI", "Suggestion failed", "Retry", "Open AI Settings",
            "Routine suggestions need an OpenRouter API key. Add yours in AI Settings to enable them.",
            "e.g. focus legs, 45 minutes", "Goal (optional)",
            "The suggestion balances your recent workout history; add a goal to steer it.",
            "Generating suggestion…", "Cancel Generation", "Generate",
            "An OpenRouter API key is required.",
            "Couldn't reach OpenRouter. Check your connection and try again.",
            "Your API key appears to be invalid. Update it in AI Settings.",
            "Your OpenRouter account is out of credits. Add credits or update the key in AI Settings.",
            "Too many requests right now. Try again in a moment.",
            "OpenRouter returned an unexpected response. Try again.",
            "The model didn't suggest any usable exercises. Try again.",
            "Why this routine",
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
