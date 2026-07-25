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
            nameTranslations: ["es": "Press de Banca con Barra"],
            summaryTranslations: ["es": "Resumen del catálogo."],
            instructionTranslations: ["es": ["Paso uno.", "Paso dos."]]
        )
    }

    @Test func nameResolvesPerLanguageWithEnglishFallback() {
        let exercise = makeCatalogExercise()

        #expect(exercise.localizedName(languageCode: "es") == "Press de Banca con Barra")
        #expect(exercise.localizedName(languageCode: "en") == "Barbell Bench Press")
        // Unsupported languages fall back to the canonical name.
        #expect(exercise.localizedName(languageCode: "fr") == "Barbell Bench Press")
    }

    @Test func emptyNameTranslationFallsBackRatherThanRenderingBlank() {
        let exercise = makeCatalogExercise()
        exercise.nameTranslations = ["es": ""]

        #expect(exercise.localizedName(languageCode: "es") == "Barbell Bench Press")
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
        // Holds in any device language, which matters: unit tests run in the
        // host app and inherit the simulator's language.
        let exercise = makeCatalogExercise()
        let code = Exercise.contentLanguageCode
        #expect(exercise.localizedName == exercise.localizedName(languageCode: code))
        #expect(exercise.localizedSummary == exercise.localizedSummary(languageCode: code))
        #expect(exercise.localizedInstructionSteps == exercise.localizedInstructionSteps(languageCode: code))
    }

    @Test func userModifiedExerciseShowsStoredTextVerbatim() {
        let exercise = makeCatalogExercise()
        exercise.name = "Press banca plano"
        exercise.summary = "My own notes."
        exercise.instructionSteps = ["Do it my way."]
        exercise.isUserModified = true

        // Translations still stored, but the override bypasses them in
        // every language.
        #expect(exercise.localizedName(languageCode: "es") == "Press banca plano")
        #expect(exercise.localizedName(languageCode: "en") == "Press banca plano")
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

        #expect(exercise.localizedName(languageCode: "es") == "My Custom Move")
        #expect(exercise.localizedSummary(languageCode: "es") == "Custom summary.")
        #expect(exercise.localizedInstructionSteps(languageCode: "es") == ["Custom step."])
    }
}
