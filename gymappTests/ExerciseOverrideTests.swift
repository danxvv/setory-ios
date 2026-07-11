//
//  ExerciseOverrideTests.swift
//  gymappTests
//
//  Covers the user-modified override semantics: once an exercise is edited,
//  its stored text wins everywhere and the catalog localization tables no
//  longer apply (see Exercise.isUserModified).
//

import Foundation
import SwiftData
import Testing
@testable import gymapp

struct ExerciseOverrideTests {
    private func makeCatalogExercise() -> Exercise {
        // Uses a real catalog id so the ExerciseNames/ExerciseContent tables
        // contain entries that the override must bypass.
        Exercise(
            id: "bench-press",
            name: "Bench Press",
            category: .strength,
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .shoulders],
            summary: "Catalog summary.",
            instructionSteps: ["Catalog step one.", "Catalog step two."]
        )
    }

    @Test func catalogExerciseResolvesThroughLocalizationTables() {
        // Locale-agnostic: stored values are deliberately not catalog text,
        // so in any device language the table value must win over them.
        let exercise = makeCatalogExercise()
        exercise.name = "Stored Fallback Name"

        #expect(exercise.localizedName != "Stored Fallback Name")
        #expect(exercise.localizedSummary != "Catalog summary.")
        #expect(exercise.localizedInstructionSteps.count == 2)
        #expect(exercise.localizedInstructionSteps[0] != "Catalog step one.")
    }

    @Test func userModifiedExerciseShowsStoredTextVerbatim() {
        let exercise = makeCatalogExercise()
        exercise.name = "Press banca plano"
        exercise.summary = "My own notes."
        exercise.instructionSteps = ["Do it my way."]
        exercise.isUserModified = true

        #expect(exercise.localizedName == "Press banca plano")
        #expect(exercise.localizedSummary == "My own notes.")
        #expect(exercise.localizedInstructionSteps == ["Do it my way."])
    }

    @Test func unknownIdFallsBackToStoredValues() {
        let exercise = Exercise(
            id: "my-custom-move",
            name: "My Custom Move",
            category: .strength,
            primaryMuscles: [.chest],
            summary: "Custom summary.",
            instructionSteps: ["Custom step."]
        )

        #expect(exercise.localizedName == "My Custom Move")
        #expect(exercise.localizedSummary == "Custom summary.")
        #expect(exercise.localizedInstructionSteps == ["Custom step."])
    }
}
