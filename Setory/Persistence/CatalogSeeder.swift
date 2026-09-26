//
//  CatalogSeeder.swift
//  Setory
//

import Foundation
import SwiftData

/// Seeds the exercise catalog into the store on launch.
/// Idempotent: exercises whose stable id already exists are not duplicated;
/// non-user-modified ones are backfilled to match the catalog (so stores
/// created before content fields existed pick them up), and user-modified
/// exercises are never touched.
struct CatalogSeeder {
    /// Must match the `version` in the bundled exercise-catalog.json
    /// (CATALOG_VERSION in tools/catalog/transform.py). Bump both together
    /// so upgraded installs reseed exactly once.
    static let bundledCatalogVersion = 2
    /// UserDefaults key holding the last successfully seeded version.
    static let catalogVersionKey = "exerciseCatalogVersion"

    enum SeedError: Error {
        case catalogMissing
    }

    /// Reads the catalog from `exercise-catalog.json` in the app bundle.
    static func loadBundledCatalog(bundle: Bundle = .main) throws -> ExerciseCatalog {
        guard let url = bundle.url(forResource: "exercise-catalog", withExtension: "json") else {
            throw SeedError.catalogMissing
        }
        return try JSONDecoder().decode(ExerciseCatalog.self, from: Data(contentsOf: url))
    }

    /// Version-gated launch path: loads and seeds the bundled catalog only
    /// when the stored version differs from the bundled one or the store has
    /// no exercises (first launch, `-uitest-reset`).
    @discardableResult
    static func seedIfNeeded(
        context: ModelContext,
        load: () throws -> ExerciseCatalog = { try CatalogSeeder.loadBundledCatalog() },
        defaults: UserDefaults = .standard
    ) throws -> Int {
        if defaults.integer(forKey: catalogVersionKey) == bundledCatalogVersion,
           try context.fetchCount(FetchDescriptor<Exercise>()) > 0 {
            return 0
        }
        let inserted = try seed(context: context, load: load)
        defaults.set(bundledCatalogVersion, forKey: catalogVersionKey)
        return inserted
    }

    /// Loads the catalog, inserts any missing exercises, and backfills
    /// catalog fields on existing non-user-modified ones. Returns the number
    /// of newly inserted exercises.
    @discardableResult
    static func seed(
        context: ModelContext,
        load: () throws -> ExerciseCatalog = { try CatalogSeeder.loadBundledCatalog() }
    ) throws -> Int {
        let catalog = try load()
        let existing = try context.fetch(FetchDescriptor<Exercise>())
        let byId = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        var inserted = 0
        var backfilled = false
        for entry in catalog.exercises {
            if let exercise = byId[entry.id] {
                guard !exercise.isUserModified else { continue }
                backfilled = align(exercise, with: entry) || backfilled
            } else {
                context.insert(Exercise(
                    id: entry.id,
                    name: entry.name,
                    category: entry.category,
                    primaryMuscles: entry.primaryMuscles,
                    secondaryMuscles: entry.secondaryMuscles,
                    summary: entry.summary,
                    instructionSteps: entry.instructions,
                    equipment: entry.equipment,
                    gifFileName: entry.gifFileName,
                    nameTranslations: entry.localizedNames ?? [:],
                    summaryTranslations: entry.localizedSummaries ?? [:],
                    instructionTranslations: entry.localizedInstructions ?? [:]
                ))
                inserted += 1
            }
        }
        if inserted > 0 || backfilled {
            try context.save()
        }
        return inserted
    }

    /// Restores user-edited exercises to their catalog values (the
    /// `-uitest-reset` path, which must not leak edits between UI tests).
    /// The catalog is loaded only when edited rows exist, so the common
    /// UI-test launch does no catalog work at all. Edited exercises whose
    /// id is missing from the catalog cannot be restored and are deleted.
    static func restorePristineCatalog(
        context: ModelContext,
        load: () throws -> ExerciseCatalog = { try CatalogSeeder.loadBundledCatalog() }
    ) throws {
        let modified = try context.fetch(
            FetchDescriptor<Exercise>(predicate: #Predicate { $0.isUserModified })
        )
        guard !modified.isEmpty else { return }
        let entries = Dictionary(uniqueKeysWithValues: try load().exercises.map { ($0.id, $0) })
        for exercise in modified {
            guard let entry = entries[exercise.id] else {
                context.delete(exercise)
                continue
            }
            exercise.isUserModified = false
            _ = align(exercise, with: entry)
        }
        try context.save()
    }

    /// Copies catalog values onto a seeded exercise. Returns true if
    /// anything actually changed, keeping repeat runs save-free.
    private static func align(_ exercise: Exercise, with entry: CatalogExercise) -> Bool {
        var changed = false
        if exercise.name != entry.name { exercise.name = entry.name; changed = true }
        if exercise.category != entry.category { exercise.category = entry.category; changed = true }
        if exercise.primaryMuscles != entry.primaryMuscles { exercise.primaryMuscles = entry.primaryMuscles; changed = true }
        if exercise.secondaryMuscles != entry.secondaryMuscles { exercise.secondaryMuscles = entry.secondaryMuscles; changed = true }
        if exercise.summary != entry.summary { exercise.summary = entry.summary; changed = true }
        if exercise.instructionSteps != entry.instructions { exercise.instructionSteps = entry.instructions; changed = true }
        if exercise.equipment != entry.equipment { exercise.equipment = entry.equipment; changed = true }
        if exercise.gifFileName != entry.gifFileName { exercise.gifFileName = entry.gifFileName; changed = true }
        let names = entry.localizedNames ?? [:]
        if exercise.nameTranslations != names { exercise.nameTranslations = names; changed = true }
        let summaries = entry.localizedSummaries ?? [:]
        if exercise.summaryTranslations != summaries { exercise.summaryTranslations = summaries; changed = true }
        let instructions = entry.localizedInstructions ?? [:]
        if exercise.instructionTranslations != instructions { exercise.instructionTranslations = instructions; changed = true }
        return changed
    }
}
