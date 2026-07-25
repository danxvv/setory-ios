//
//  LocalizationTests.swift
//  gymappTests
//
//  Guards catalog completeness: every catalog exercise must carry Spanish
//  content translations (names are English-only by design — the dataset
//  ships no translated names), and every UI string catalog key must have a
//  Spanish value.
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

    @Test func everyCatalogExerciseHasSpanishContent() throws {
        let entries = try BundledCatalogSource().loadCatalog().exercises
        #expect(!entries.isEmpty)

        for entry in entries {
            #expect(
                entry.localizedSummaries["es"]?.isEmpty == false,
                "Exercise id '\(entry.id)' has no Spanish summary"
            )
            #expect(
                entry.localizedInstructions["es"]?.isEmpty == false,
                "Exercise id '\(entry.id)' has no Spanish instruction steps"
            )
        }
    }

    @Test func everyEquipmentValueHasSpanishDisplayName() throws {
        // The English display strings used as keys by Equipment.displayName.
        // displayName itself resolves in the host app's language, so the
        // keys are listed literally; the count guard keeps them in sync.
        let keys = [
            "Assisted", "Band", "Barbell", "Body Weight", "Bosu Ball", "Cable",
            "Dumbbell", "Elliptical Machine", "EZ Barbell", "Hammer Machine",
            "Kettlebell", "Leverage Machine", "Medicine Ball", "Olympic Barbell",
            "Resistance Band", "Roller", "Rope", "SkiErg Machine", "Sled Machine",
            "Smith Machine", "Stability Ball", "Stationary Bike", "Stepmill Machine",
            "Tire", "Trap Bar", "Upper Body Ergometer", "Weighted", "Wheel Roller",
        ]
        #expect(keys.count == Equipment.allCases.count)
        let esBundle = try spanishBundle()

        for key in keys {
            let localized = esBundle.localizedString(forKey: key, value: missing, table: nil)
            #expect(
                localized != missing,
                "Equipment key '\(key)' has no Spanish value in Localizable.xcstrings"
            )
        }
    }

    /// Strings added with the catalog replacement (filters, media, about).
    @Test func everyCatalogReplacementKeyHasSpanishValue() throws {
        let newKeys = [
            "Muscle", "Equipment", "All muscles", "All equipment", "Clear filters",
            "About & Licenses", "Exercise media", "Exercise data license",
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

    /// Every user-facing string added by the photo exercise-match feature,
    /// including the privacy note it rewrote. The error messages are shared
    /// with the suggestion flow and audited above.
    @Test func everyPhotoMatchKeyHasSpanishValue() throws {
        let newKeys = [
            "Match from Photo", "Photo match failed",
            "Photo matching needs an OpenRouter API key. Add yours in AI Settings to enable it.",
            "Photos", "Add a photo of the machine, the equipment, or the exercise being performed.",
            "Choose Photos", "Take Photo", "Remove photo",
            "Up to %lld photos are sent to OpenRouter under your API key.",
            "Identifying exercises…", "Cancel Match", "Find Exercises",
            "Matches", "Select the exercises to add to this routine.",
            "No matching exercises", "Try a photo that shows the whole machine or its label.",
            "Try Other Photos",
            "High match", "Possible match", "Weak match",
            // Optional description + main-muscle hints, and the privacy
            // note they rewrote again.
            "Details", "What the machine or exercise looks like",
            "Main muscle", "Any muscle",
            "No exercise in your library targets that muscle. Pick another main muscle or clear it.",
            "Optional. Picking a main muscle sends only that muscle's exercises to OpenRouter.",
            "When you request a suggestion, your exercise IDs, set counts, muscle data, session dates, and optional goal are sent to OpenRouter under your API key. When you request a photo match, the photos you attach are sent along with the exercise catalog (IDs, names, and muscle data) and the description or main muscle you add; the app never stores them. Requests happen only when you ask for a suggestion or a photo match.",
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

    /// Every user-facing string added by the routine-media feature (the
    /// logging screen's thumbnail viewer) must have a Spanish value. The
    /// sheet's "Done" button reuses the existing key audited above.
    @Test func everyRoutineMediaKeyHasSpanishValue() throws {
        let newKeys = [
            "Show demonstration for %@",
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

}
