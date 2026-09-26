//
//  AppModelContainer.swift
//  Setory
//
//  The app's SwiftData schema and the launch-time container construction:
//  create the store, apply the UI-test reset when asked, seed the bundled
//  catalog when its version moved, then apply UI-test session seeding.
//  Extracted from SetoryApp so the entry point only wires dependencies.
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
            // Order matters: a UI-test reset runs before catalog seeding so a
            // pristine catalog is in place, and session seeding runs after so
            // its series can resolve real exercise records.
            TestOverrides.applyStoreReset(context: container.mainContext)
            do {
                try CatalogSeeder.seedIfNeeded(context: container.mainContext)
            } catch {
                assertionFailure("Catalog seeding failed: \(error)")
            }
            TestOverrides.applySessionSeeding(context: container.mainContext)
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
