//
//  CatalogSeeder.swift
//  gymapp
//

import Foundation
import SwiftData

/// Seeds the exercise catalog into the store on launch.
/// Idempotent: exercises whose stable id already exists are not duplicated;
/// non-user-modified ones are backfilled to match the catalog (so stores
/// created before content fields existed pick them up), and user-modified
/// exercises are never touched.
struct CatalogSeeder {
    /// Loads the catalog from the given source, inserts any missing
    /// exercises, and backfills catalog fields on existing non-user-modified
    /// ones. Returns the number of newly inserted exercises.
    @discardableResult
    static func seed(
        context: ModelContext,
        source: ExerciseCatalogSource = BundledCatalogSource()
    ) throws -> Int {
        let catalog = try source.loadCatalog()
        let existing = try context.fetch(FetchDescriptor<Exercise>())
        let byId = Dictionary(uniqueKeysWithValues: existing.map { ($0.id, $0) })

        var inserted = 0
        var backfilled = false
        for entry in catalog {
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
                    instructionSteps: entry.instructions
                ))
                inserted += 1
            }
        }
        if inserted > 0 || backfilled {
            try context.save()
        }
        return inserted
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
        return changed
    }
}
