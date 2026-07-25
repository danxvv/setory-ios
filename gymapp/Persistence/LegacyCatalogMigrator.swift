//
//  LegacyCatalogMigrator.swift
//  gymapp
//
//  One-time migration from the legacy 40-exercise catalog to the Gym visual
//  dataset catalog. Legacy rows with a dataset equivalent are remapped to
//  the new id *in place*, so workout-series and template-item references
//  survive untouched; the seeder then backfills their catalog fields.
//  Legacy rows without an equivalent are kept as user-space exercises when
//  referenced by history or templates, and deleted otherwise.
//

import Foundation
import SwiftData

/// The hand-reviewed legacy-id table (tools/catalog/legacy-mapping.json,
/// copied into app resources by the transform).
struct LegacyCatalogMapping: Codable, Equatable {
    /// Legacy id -> dataset id (e.g. "bench-press" -> "gv0025").
    let mapped: [String: String]
    /// Legacy ids with no dataset equivalent.
    let unmapped: [String]
}

enum LegacyCatalogMigrator {
    enum MigratorError: Error {
        case resourceMissing
    }

    static func loadBundledMapping(bundle: Bundle = .main) throws -> LegacyCatalogMapping {
        guard let url = bundle.url(forResource: "legacy-mapping", withExtension: "json") else {
            throw MigratorError.resourceMissing
        }
        return try JSONDecoder().decode(LegacyCatalogMapping.self, from: Data(contentsOf: url))
    }

    /// Migrates any legacy catalog rows present in the store. Idempotent:
    /// once remapped/converted/deleted, no legacy ids remain, so repeat runs
    /// are no-ops. Returns counts for logging and tests.
    @discardableResult
    static func migrate(
        context: ModelContext,
        mapping: LegacyCatalogMapping
    ) throws -> (remapped: Int, preserved: Int, deleted: Int) {
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        let existingIds = Set(exercises.map(\.id))

        var remapped = 0
        var preserved = 0
        var deleted = 0
        for exercise in exercises where !exercise.isCustom {
            if let newId = mapping.mapped[exercise.id], !existingIds.contains(newId) {
                exercise.id = newId
                remapped += 1
            } else if mapping.unmapped.contains(exercise.id) || mapping.mapped[exercise.id] != nil {
                // No dataset equivalent, or the target id already exists
                // (partial earlier run): keep the row for its references,
                // otherwise drop it before seeding.
                if try isReferenced(exercise, in: context) {
                    exercise.isCustom = true
                    preserved += 1
                } else {
                    context.delete(exercise)
                    deleted += 1
                }
            }
        }
        if remapped + preserved + deleted > 0 {
            try context.save()
        }
        return (remapped, preserved, deleted)
    }

    /// Whether any workout series or template item points at the exercise.
    private static func isReferenced(_ exercise: Exercise, in context: ModelContext) throws -> Bool {
        let id = exercise.id
        let seriesCount = try context.fetchCount(
            FetchDescriptor<WorkoutSeries>(predicate: #Predicate { $0.exercise?.id == id })
        )
        if seriesCount > 0 { return true }
        let itemCount = try context.fetchCount(
            FetchDescriptor<RoutineTemplateItem>(predicate: #Predicate { $0.exercise?.id == id })
        )
        return itemCount > 0
    }
}
