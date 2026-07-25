//
//  ExerciseOverrideTests.swift
//  gymappTests
//
//  Covers content-language resolution and the user-modified override
//  semantics: once an exercise is edited, its stored text wins everywhere
//  and the content translations no longer apply (see Exercise.isUserModified).
//

import Foundation
import SwiftData
import Testing
@testable import gymapp

struct ExerciseOverrideTests {
    private func makeCatalogExercise() -> Exercise {
        Exercise(
            id: "gv0025",
            name: "Barbell Bench Press",
            category: .strength,
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .shoulders],
            summary: "Catalog summary.",
            instructionSteps: ["Catalog step one.", "Catalog step two."],
            summaryTranslations: ["es": "Resumen del catálogo."],
            instructionTranslations: ["es": ["Paso uno.", "Paso dos."]]
        )
    }

    @Test func displayNameIsAlwaysTheStoredName() {
        // Catalog names are English-only by design; there is no name table.
        let exercise = makeCatalogExercise()
        #expect(exercise.localizedName == "Barbell Bench Press")
    }

    @Test func contentResolvesPerLanguageWithEnglishFallback() {
        let exercise = makeCatalogExercise()

        #expect(exercise.localizedSummary(languageCode: "es") == "Resumen del catálogo.")
        #expect(exercise.localizedInstructionSteps(languageCode: "es") == ["Paso uno.", "Paso dos."])
        #expect(exercise.localizedSummary(languageCode: "en") == "Catalog summary.")
        #expect(exercise.localizedInstructionSteps(languageCode: "en") == ["Catalog step one.", "Catalog step two."])
        // Unsupported languages fall back to canonical English.
        #expect(exercise.localizedSummary(languageCode: "fr") == "Catalog summary.")
        #expect(exercise.localizedInstructionSteps(languageCode: "fr") == ["Catalog step one.", "Catalog step two."])
    }

    @Test func currentLanguageAccessorMatchesExplicitLookup() {
        let exercise = makeCatalogExercise()
        let code = Exercise.contentLanguageCode
        #expect(exercise.localizedSummary == exercise.localizedSummary(languageCode: code))
        #expect(exercise.localizedInstructionSteps == exercise.localizedInstructionSteps(languageCode: code))
    }

    @Test func userModifiedExerciseShowsStoredTextVerbatim() {
        let exercise = makeCatalogExercise()
        exercise.name = "Press banca plano"
        exercise.summary = "My own notes."
        exercise.instructionSteps = ["Do it my way."]
        exercise.isUserModified = true

        #expect(exercise.localizedName == "Press banca plano")
        // Translations still stored, but the override bypasses them in
        // every language.
        #expect(exercise.localizedSummary(languageCode: "es") == "My own notes.")
        #expect(exercise.localizedSummary(languageCode: "en") == "My own notes.")
        #expect(exercise.localizedInstructionSteps(languageCode: "es") == ["Do it my way."])
    }

    @Test func exerciseWithoutTranslationsFallsBackToStoredValues() {
        let exercise = Exercise(
            id: "my-custom-move",
            name: "My Custom Move",
            category: .strength,
            primaryMuscles: [.chest],
            summary: "Custom summary.",
            instructionSteps: ["Custom step."]
        )

        #expect(exercise.localizedName == "My Custom Move")
        #expect(exercise.localizedSummary(languageCode: "es") == "Custom summary.")
        #expect(exercise.localizedInstructionSteps(languageCode: "es") == ["Custom step."])
    }
}
