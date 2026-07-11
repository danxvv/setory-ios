//
//  CatalogSeederTests.swift
//  gymappTests
//

import Foundation
import SwiftData
import Testing
@testable import gymapp

struct CatalogSeederTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([Exercise.self, WorkoutSession.self, WorkoutSeries.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return ModelContext(try ModelContainer(for: schema, configurations: [config]))
    }

    private struct StubSource: ExerciseCatalogSource {
        var entries: [CatalogExercise]
        func loadCatalog() throws -> [CatalogExercise] { entries }
    }

    private let benchPress = CatalogExercise(
        id: "bench-press",
        name: "Bench Press",
        category: .strength,
        primaryMuscles: [.chest],
        secondaryMuscles: [.triceps, .shoulders],
        summary: "A chest press.",
        instructions: ["Lie down.", "Press the bar."]
    )

    @Test func firstLaunchSeedsFullCatalog() throws {
        let context = try makeContext()

        let inserted = try CatalogSeeder.seed(context: context)

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(inserted > 0)
        #expect(exercises.count == inserted)
        // Every seeded exercise satisfies the catalog contract.
        for exercise in exercises {
            #expect(!exercise.primaryMuscles.isEmpty)
            #expect(exercise.isCustom == false)
            #expect(exercise.isUserModified == false)
            #expect(!exercise.summary.isEmpty)
            #expect(!exercise.instructionSteps.isEmpty)
        }
        #expect(exercises.contains { $0.category == .strength })
        #expect(exercises.contains { $0.category == .cardio })
    }

    @Test func secondLaunchInsertsNoDuplicates() throws {
        let context = try makeContext()

        let first = try CatalogSeeder.seed(context: context)
        let second = try CatalogSeeder.seed(context: context)

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(second == 0)
        #expect(exercises.count == first)
    }

    @Test func upgradeBackfillsContentOnExistingExercises() throws {
        let context = try makeContext()
        // Simulate a store seeded before summary/instructions existed.
        context.insert(Exercise(
            id: benchPress.id,
            name: benchPress.name,
            category: .strength,
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .shoulders]
        ))
        try context.save()

        let inserted = try CatalogSeeder.seed(context: context, source: StubSource(entries: [benchPress]))

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(inserted == 0)
        #expect(exercises.count == 1)
        #expect(exercises[0].summary == benchPress.summary)
        #expect(exercises[0].instructionSteps == benchPress.instructions)
    }

    @Test func backfillIsIdempotent() throws {
        let context = try makeContext()
        let source = StubSource(entries: [benchPress])

        try CatalogSeeder.seed(context: context, source: source)
        try CatalogSeeder.seed(context: context, source: source)

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count == 1)
        #expect(exercises[0].summary == benchPress.summary)
    }

    @Test func userModifiedExerciseIsNeverTouched() throws {
        let context = try makeContext()
        let source = StubSource(entries: [benchPress])
        try CatalogSeeder.seed(context: context, source: source)

        let exercise = try #require(try context.fetch(FetchDescriptor<Exercise>()).first)
        exercise.name = "Press banca plano"
        exercise.summary = "My own notes."
        exercise.instructionSteps = ["My way."]
        exercise.isUserModified = true
        try context.save()

        try CatalogSeeder.seed(context: context, source: source)

        let reloaded = try #require(try context.fetch(FetchDescriptor<Exercise>()).first)
        #expect(reloaded.name == "Press banca plano")
        #expect(reloaded.summary == "My own notes.")
        #expect(reloaded.instructionSteps == ["My way."])
    }

    @Test func alphabeticalFetchForSelectionUI() throws {
        let context = try makeContext()
        try CatalogSeeder.seed(context: context)

        let descriptor = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name)])
        let names = try context.fetch(descriptor).map(\.name)

        #expect(names == names.sorted())
        #expect(!names.isEmpty)
    }
}
