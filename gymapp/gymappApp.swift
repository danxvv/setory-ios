//
//  gymappApp.swift
//  gymapp
//
//  Created by Daniel Temalatzi Mojica on 10/07/26.
//

import SwiftUI
import SwiftData

@main
struct gymappApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            WorkoutSession.self,
            WorkoutSeries.self,
            RoutineTemplate.self,
            RoutineTemplateItem.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            if CommandLine.arguments.contains("-uitest-reset") {
                try? container.mainContext.delete(model: WorkoutSeries.self)
                try? container.mainContext.delete(model: WorkoutSession.self)
                try? container.mainContext.delete(model: RoutineTemplateItem.self)
                try? container.mainContext.delete(model: RoutineTemplate.self)
                // Also restore a pristine catalog (drops user edits) so UI
                // tests never inherit renames from a previous run; the
                // seeder below re-inserts everything.
                try? container.mainContext.delete(model: Exercise.self)
                try? container.mainContext.save()
            }
            do {
                try CatalogSeeder.seed(context: container.mainContext)
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
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(sharedModelContainer)
    }
}

/// Inserts deterministic saved sessions for UI tests (`-uitest-seed`,
/// normally combined with `-uitest-reset`): today with Bench Press and
/// Treadmill Run, plus a Squat-only session three days earlier.
private enum UITestSeeding {
    static func seedSessions(context: ModelContext) throws {
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        func exercise(withId id: String) -> Exercise? {
            exercises.first { $0.id == id }
        }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)

        let todaySession = WorkoutSession(date: today)
        context.insert(todaySession)
        let bench = WorkoutSeries(order: 0, exercise: exercise(withId: "bench-press"), reps: 10, weightKg: 40)
        bench.session = todaySession
        context.insert(bench)
        let run = WorkoutSeries(order: 1, exercise: exercise(withId: "treadmill-run"), durationSeconds: 900)
        run.session = todaySession
        context.insert(run)

        let earlierSession = WorkoutSession(date: calendar.date(byAdding: .day, value: -3, to: today) ?? today)
        context.insert(earlierSession)
        let squat = WorkoutSeries(order: 0, exercise: exercise(withId: "squat"), reps: 8, weightKg: 70)
        squat.session = earlierSession
        context.insert(squat)

        try context.save()
    }
}
