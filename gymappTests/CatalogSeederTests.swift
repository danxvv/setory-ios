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

    private func catalog(_ entries: [CatalogExercise]) -> ExerciseCatalog {
        ExerciseCatalog(version: CatalogSeeder.bundledCatalogVersion, datasetCommit: nil, exercises: entries)
    }

    /// Fails the test if the seeder loads the catalog when the version
    /// gate says nothing changed.
    private struct UnexpectedLoad: Error {}
    private func unexpectedLoad() throws -> ExerciseCatalog { throw UnexpectedLoad() }

    private func makeDefaults() -> UserDefaults {
        let defaults = UserDefaults(suiteName: "seeder-tests-\(UUID().uuidString)")!
        return defaults
    }

    private let benchPress = CatalogExercise(
        id: "gv0025",
        name: "Barbell Bench Press",
        category: .strength,
        primaryMuscles: [.chest],
        secondaryMuscles: [.triceps, .shoulders],
        equipment: .barbell,
        gifFileName: "0025-test.gif",
        summary: "A chest press.",
        instructions: ["Lie down.", "Press the bar."],
        localizedNames: ["es": "Press de Banca con Barra"],
        localizedSummaries: ["es": "Un press de pecho."],
        localizedInstructions: ["es": ["Túmbate.", "Empuja la barra."]]
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
            #expect(exercise.isUserModified == false)
            #expect(!exercise.summary.isEmpty)
            #expect(!exercise.instructionSteps.isEmpty)
            #expect(exercise.equipment != nil)
            #expect(exercise.hasMedia)
            #expect(
                exercise.nameTranslations["es"]?.isEmpty == false,
                "'\(exercise.id)' seeded without a Spanish name"
            )
        }
        #expect(exercises.contains { $0.category == .strength })
        #expect(exercises.contains { $0.category == .cardio })
    }

    @Test func bundledVersionConstantMatchesCatalogJSON() throws {
        let catalog = try CatalogSeeder.loadBundledCatalog()
        #expect(catalog.version == CatalogSeeder.bundledCatalogVersion)
    }

    @Test func versionGateSkipsParsingWhenNothingChanged() throws {
        let context = try makeContext()
        let defaults = makeDefaults()
        context.insert(Exercise(id: "gv0001", name: "Any", category: .strength, primaryMuscles: [.abs]))
        try context.save()
        defaults.set(CatalogSeeder.bundledCatalogVersion, forKey: CatalogSeeder.catalogVersionKey)

        // unexpectedLoad proves the catalog is never loaded.
        let inserted = try CatalogSeeder.seedIfNeeded(context: context, load: unexpectedLoad, defaults: defaults)

        #expect(inserted == 0)
    }

    @Test func versionBumpTriggersReseedAndStampsVersion() throws {
        let context = try makeContext()
        let defaults = makeDefaults()
        defaults.set(CatalogSeeder.bundledCatalogVersion - 1, forKey: CatalogSeeder.catalogVersionKey)

        let inserted = try CatalogSeeder.seedIfNeeded(context: context, load: { catalog([benchPress]) }, defaults: defaults)

        #expect(inserted == 1)
        #expect(defaults.integer(forKey: CatalogSeeder.catalogVersionKey) == CatalogSeeder.bundledCatalogVersion)
    }

    @Test func emptyStoreReseedsEvenWhenVersionMatches() throws {
        // The -uitest-reset path: exercises wiped but the stamp remains.
        let context = try makeContext()
        let defaults = makeDefaults()
        defaults.set(CatalogSeeder.bundledCatalogVersion, forKey: CatalogSeeder.catalogVersionKey)

        let inserted = try CatalogSeeder.seedIfNeeded(context: context, load: { catalog([benchPress]) }, defaults: defaults)

        #expect(inserted == 1)
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

        let inserted = try CatalogSeeder.seed(context: context, load: { catalog([benchPress]) })

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(inserted == 0)
        #expect(exercises.count == 1)
        #expect(exercises[0].summary == benchPress.summary)
        #expect(exercises[0].instructionSteps == benchPress.instructions)
        // The name-translation table lands on stores seeded before it existed.
        #expect(exercises[0].nameTranslations == benchPress.localizedNames)
        #expect(exercises[0].localizedName(languageCode: "es") == "Press de Banca con Barra")
    }

    @Test func backfillIsIdempotent() throws {
        let context = try makeContext()
        let load = { catalog([benchPress]) }

        try CatalogSeeder.seed(context: context, load: load)
        try CatalogSeeder.seed(context: context, load: load)

        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        #expect(exercises.count == 1)
        #expect(exercises[0].summary == benchPress.summary)
    }

    @Test func userModifiedExerciseIsNeverTouched() throws {
        let context = try makeContext()
        let load = { catalog([benchPress]) }
        try CatalogSeeder.seed(context: context, load: load)

        let exercise = try #require(try context.fetch(FetchDescriptor<Exercise>()).first)
        exercise.name = "Press banca plano"
        exercise.summary = "My own notes."
        exercise.instructionSteps = ["My way."]
        exercise.isUserModified = true
        try context.save()

        try CatalogSeeder.seed(context: context, load: load)

        let reloaded = try #require(try context.fetch(FetchDescriptor<Exercise>()).first)
        #expect(reloaded.name == "Press banca plano")
        #expect(reloaded.summary == "My own notes.")
        #expect(reloaded.instructionSteps == ["My way."])
        // The stored translation survives but no longer resolves: the
        // user's name wins in every language.
        #expect(reloaded.localizedName(languageCode: "es") == "Press banca plano")
    }

    @Test func restorePristineCatalogRealignsEditedExercise() throws {
        let context = try makeContext()
        let load = { catalog([benchPress]) }
        try CatalogSeeder.seed(context: context, load: load)
        let exercise = try #require(try context.fetch(FetchDescriptor<Exercise>()).first)
        exercise.name = "Press banca plano"
        exercise.summary = "My own notes."
        exercise.nameTranslations = [:]
        exercise.isUserModified = true
        try context.save()

        try CatalogSeeder.restorePristineCatalog(context: context, load: load)

        let reloaded = try #require(try context.fetch(FetchDescriptor<Exercise>()).first)
        #expect(reloaded.name == benchPress.name)
        #expect(reloaded.summary == benchPress.summary)
        #expect(reloaded.nameTranslations == benchPress.localizedNames)
        #expect(reloaded.isUserModified == false)
    }

    @Test func restorePristineCatalogSkipsParseWhenNothingEdited() throws {
        let context = try makeContext()
        context.insert(Exercise(id: benchPress.id, name: benchPress.name, category: .strength, primaryMuscles: [.chest]))
        try context.save()

        // unexpectedLoad proves the catalog is never loaded on the common
        // -uitest-reset launch where no test has edited an exercise.
        try CatalogSeeder.restorePristineCatalog(context: context, load: unexpectedLoad)
    }

    @Test func restorePristineCatalogDeletesEditedOrphans() throws {
        let context = try makeContext()
        // An edited exercise whose id left the catalog cannot be restored.
        context.insert(Exercise(
            id: "gone01", name: "Renamed Orphan", category: .strength,
            primaryMuscles: [.chest], isUserModified: true
        ))
        try context.save()

        try CatalogSeeder.restorePristineCatalog(context: context, load: { catalog([benchPress]) })

        #expect(try context.fetchCount(FetchDescriptor<Exercise>()) == 0)
    }

    @Test func alphabeticalFetchForSelectionUI() throws {
        let context = try makeContext()
        try CatalogSeeder.seed(context: context)

        // Same locale-aware ordering the selection UIs apply in memory.
        let descriptor = FetchDescriptor<Exercise>(sortBy: [SortDescriptor(\.name, comparator: .localizedStandard)])
        let names = try context.fetch(descriptor).map(\.name)

        #expect(names == names.sorted { $0.localizedStandardCompare($1) == .orderedAscending })
        #expect(!names.isEmpty)
    }
}
