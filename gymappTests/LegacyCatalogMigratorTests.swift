//
//  LegacyCatalogMigratorTests.swift
//  gymappTests
//
//  The one-time legacy → dataset catalog migration: in-place id remaps
//  that keep workout history, custom-conversion for referenced orphans,
//  deletion of unreferenced ones, and idempotence. The full-flow test
//  runs the real seedIfNeeded pipeline over a simulated legacy store.
//

import Foundation
import SwiftData
import Testing
@testable import gymapp

struct LegacyCatalogMigratorTests {
    private func makeContext() throws -> ModelContext {
        let schema = Schema([
            Exercise.self, WorkoutSession.self, WorkoutSeries.self,
            RoutineTemplate.self, RoutineTemplateItem.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return ModelContext(try ModelContainer(for: schema, configurations: [config]))
    }

    private let mapping = LegacyCatalogMapping(
        mapped: ["bench-press": "gv0025", "squat": "gv0043"],
        unmapped: ["face-pull", "rowing-machine"]
    )

    private func insertLegacyExercise(_ id: String, name: String, in context: ModelContext) -> Exercise {
        let exercise = Exercise(id: id, name: name, category: .strength, primaryMuscles: [.chest])
        context.insert(exercise)
        return exercise
    }

    @discardableResult
    private func logSeries(for exercise: Exercise, in context: ModelContext) -> WorkoutSeries {
        let session = WorkoutSession(date: Calendar.current.startOfDay(for: .now))
        context.insert(session)
        let series = WorkoutSeries(order: 0, exercise: exercise, reps: 10, weightKg: 40)
        series.session = session
        context.insert(series)
        return series
    }

    @Test func mappedExerciseIsRemappedInPlaceKeepingHistory() throws {
        let context = try makeContext()
        let bench = insertLegacyExercise("bench-press", name: "Bench Press", in: context)
        let series = logSeries(for: bench, in: context)
        try context.save()

        let result = try LegacyCatalogMigrator.migrate(context: context, mapping: mapping)

        #expect(result.remapped == 1)
        #expect(bench.id == "gv0025")
        #expect(series.exercise?.id == "gv0025")
        #expect(try context.fetch(FetchDescriptor<Exercise>()).count == 1)
    }

    @Test func mappedUserModifiedExerciseKeepsTextButGainsNewId() throws {
        let context = try makeContext()
        let bench = insertLegacyExercise("bench-press", name: "Mi press", in: context)
        bench.isUserModified = true
        bench.summary = "My notes."
        try context.save()

        try LegacyCatalogMigrator.migrate(context: context, mapping: mapping)

        #expect(bench.id == "gv0025")
        #expect(bench.name == "Mi press")
        #expect(bench.summary == "My notes.")
        #expect(bench.isUserModified)
    }

    @Test func unmappedExerciseWithHistoryBecomesCustom() throws {
        let context = try makeContext()
        let facePull = insertLegacyExercise("face-pull", name: "Face Pull", in: context)
        logSeries(for: facePull, in: context)
        try context.save()

        let result = try LegacyCatalogMigrator.migrate(context: context, mapping: mapping)

        #expect(result.preserved == 1)
        #expect(facePull.isCustom)
        #expect(facePull.id == "face-pull")
        let series = try context.fetch(FetchDescriptor<WorkoutSeries>())
        #expect(series.first?.exercise?.id == "face-pull")
    }

    @Test func unmappedExerciseReferencedByTemplateBecomesCustom() throws {
        let context = try makeContext()
        let facePull = insertLegacyExercise("face-pull", name: "Face Pull", in: context)
        let template = RoutineTemplate(name: "Pull Day")
        context.insert(template)
        let item = RoutineTemplateItem(order: 0, targetSets: 3, exercise: facePull)
        item.template = template
        context.insert(item)
        try context.save()

        let result = try LegacyCatalogMigrator.migrate(context: context, mapping: mapping)

        #expect(result.preserved == 1)
        #expect(facePull.isCustom)
    }

    @Test func unreferencedUnmappedExerciseIsDeleted() throws {
        let context = try makeContext()
        insertLegacyExercise("rowing-machine", name: "Rowing Machine", in: context)
        try context.save()

        let result = try LegacyCatalogMigrator.migrate(context: context, mapping: mapping)

        #expect(result.deleted == 1)
        #expect(try context.fetch(FetchDescriptor<Exercise>()).isEmpty)
    }

    @Test func secondRunIsANoOp() throws {
        let context = try makeContext()
        let bench = insertLegacyExercise("bench-press", name: "Bench Press", in: context)
        logSeries(for: bench, in: context)
        insertLegacyExercise("rowing-machine", name: "Rowing Machine", in: context)
        try context.save()

        _ = try LegacyCatalogMigrator.migrate(context: context, mapping: mapping)
        let second = try LegacyCatalogMigrator.migrate(context: context, mapping: mapping)

        #expect(second == (0, 0, 0))
    }

    @Test func customExercisesAreLeftAlone() throws {
        let context = try makeContext()
        let custom = insertLegacyExercise("face-pull", name: "My Face Pull", in: context)
        custom.isCustom = true
        try context.save()

        let result = try LegacyCatalogMigrator.migrate(context: context, mapping: mapping)

        #expect(result == (0, 0, 0))
        #expect(try context.fetch(FetchDescriptor<Exercise>()).count == 1)
    }

    /// The real upgrade path: a store seeded with legacy exercises and
    /// history goes through seedIfNeeded and comes out with the full new
    /// catalog, intact history, and no duplicates.
    @Test func fullUpgradeFlowPreservesHistoryAndSeedsNewCatalog() throws {
        let context = try makeContext()
        let defaults = UserDefaults(suiteName: "migrator-tests-\(UUID().uuidString)")!
        let bench = insertLegacyExercise("bench-press", name: "Bench Press", in: context)
        logSeries(for: bench, in: context)
        let facePull = insertLegacyExercise("face-pull", name: "Face Pull", in: context)
        logSeries(for: facePull, in: context)
        insertLegacyExercise("rowing-machine", name: "Rowing Machine", in: context)
        try context.save()

        try CatalogSeeder.seedIfNeeded(context: context, defaults: defaults)

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        let byId = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
        let catalogCount = try BundledCatalogSource().loadCatalog().exercises.count
        // Full catalog plus the preserved face-pull orphan; rowing-machine
        // was unreferenced and is gone.
        #expect(exercises.count == catalogCount + 1)
        #expect(byId["bench-press"] == nil)
        #expect(byId["rowing-machine"] == nil)
        #expect(byId["face-pull"]?.isCustom == true)
        // The remapped row was aligned to catalog content by the seeder.
        let gvBench = try #require(byId["gv0025"])
        #expect(gvBench.name == "Barbell Bench Press")
        #expect(gvBench.hasMedia)
        // History survived on both rows.
        let series = try context.fetch(FetchDescriptor<WorkoutSeries>())
        #expect(Set(series.compactMap { $0.exercise?.id }) == ["gv0025", "face-pull"])
    }
}
