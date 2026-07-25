//
//  AppModelContainer.swift
//  gymapp
//
//  The app's SwiftData schema and the launch-time container construction:
//  create the store, apply the UI-test reset when asked, seed the bundled
//  catalog when its version moved, then apply UI-test session seeding.
//  Extracted from gymappApp so the entry point only wires dependencies.
//

import Foundation
import SwiftData

enum AppModelContainer {
    /// Every persisted model. Adding one here is what makes it migratable.
    static let schema = Schema([
        Exercise.self,
        WorkoutSession.self,
        WorkoutSeries.self,
        RoutineTemplate.self,
        RoutineTemplateItem.self,
    ])

    /// Builds the on-disk container. Traps on failure: without a store there
    /// is no app, and a silent in-memory fallback would quietly eat the
    /// user's history.
    static func make() -> ModelContainer {
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            if CommandLine.arguments.contains("-uitest-reset") {
                reset(context: container.mainContext)
            }
            do {
                try CatalogSeeder.seedIfNeeded(context: container.mainContext)
            } catch {
                assertionFailure("Catalog seeding failed: \(error)")
            }
            if CommandLine.arguments.contains("-uitest-seed") {
                do {
                    try UITestSeeding.seedSessions(context: container.mainContext)
                } catch {
                    assertionFailure("UI-test session seeding failed: \(error)")
                }
            }
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    /// The `-uitest-reset` path: drop all user-generated data and restore a
    /// pristine catalog (dropping user edits) so UI tests never inherit
    /// renames from a previous run. Wiping and reseeding all ~1300 Exercise
    /// rows here dominated every UI-test launch; instead drop custom
    /// exercises and re-align edited ones, parsing the catalog only when
    /// edits exist.
    private static func reset(context: ModelContext) {
        try? context.delete(model: WorkoutSeries.self)
        try? context.delete(model: WorkoutSession.self)
        try? context.delete(model: RoutineTemplateItem.self)
        try? context.delete(model: RoutineTemplate.self)
        try? context.delete(model: Exercise.self, where: #Predicate { $0.isCustom })
        try? CatalogSeeder.restorePristineCatalog(context: context)
        try? context.save()
    }
}
