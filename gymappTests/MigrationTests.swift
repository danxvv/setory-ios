//
//  MigrationTests.swift
//  gymappTests
//
//  Opening a store created before the RoutineTemplate models existed must
//  migrate lightweight: existing data stays readable and the new template
//  models are usable in the same store.
//

import Foundation
import SwiftData
import Testing
@testable import gymapp

struct MigrationTests {
    @Test func preTemplateStoreOpensWithTemplateSchema() throws {
        let url = URL.temporaryDirectory.appending(component: "migration-\(UUID().uuidString).store")
        defer {
            try? FileManager.default.removeItem(at: url)
        }

        // Populate a store with the pre-template schema, then release it.
        do {
            let oldSchema = Schema([Exercise.self, WorkoutSession.self, WorkoutSeries.self])
            let old = try ModelContainer(
                for: oldSchema,
                configurations: [ModelConfiguration(schema: oldSchema, url: url)]
            )
            let context = ModelContext(old)
            let bench = Exercise(id: "bench-press", name: "Bench Press", category: .strength, primaryMuscles: [.chest])
            context.insert(bench)
            let session = WorkoutSession(date: .now)
            context.insert(session)
            let series = WorkoutSeries(order: 0, exercise: bench, reps: 10, weightKg: 40)
            series.session = session
            context.insert(series)
            try context.save()
        }

        // Reopen the same file with the full schema (additive change only).
        let newSchema = Schema([
            Exercise.self, WorkoutSession.self, WorkoutSeries.self,
            RoutineTemplate.self, RoutineTemplateItem.self,
        ])
        let migrated = try ModelContainer(
            for: newSchema,
            configurations: [ModelConfiguration(schema: newSchema, url: url)]
        )
        let context = ModelContext(migrated)

        // Old data survived.
        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        #expect(sessions.count == 1)
        #expect(sessions.first?.orderedSeries.first?.exercise?.id == "bench-press")

        // New models are usable in the migrated store.
        let bench = try #require(try context.fetch(FetchDescriptor<Exercise>()).first)
        let template = RoutineTemplate(name: "Post-migration")
        context.insert(template)
        let item = RoutineTemplateItem(order: 0, targetSets: 4, exercise: bench)
        item.template = template
        context.insert(item)
        try context.save()

        let templates = try context.fetch(FetchDescriptor<RoutineTemplate>())
        #expect(templates.count == 1)
        #expect(templates.first?.orderedItems.first?.exercise?.id == "bench-press")
    }
}
