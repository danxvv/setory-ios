//
//  gymappApp.swift
//  gymapp
//
//  Created by Daniel Temalatzi Mojica on 10/07/26.
//

import SwiftUI
import SwiftData
import UIKit

@main
struct gymappApp: App {
    /// AI dependencies resolved once at launch: Keychain + OpenRouter
    /// normally, or an in-memory store + stub services under
    /// `-uitest-ai <scenario>` / `-uitest-photo-match <scenario>`
    /// (success / error / no-key) so UI tests never touch the network or
    /// the real Keychain.
    private let aiKeyStore: any APIKeyStoring
    private let aiSuggestionService: any RoutineSuggestionService
    private let aiPhotoMatchService: any PhotoExerciseMatchService
    /// Media store resolved once at launch; `-uitest-offline-media`
    /// disables its network path so UI tests are deterministic.
    private let mediaStore: ExerciseMediaStore

    init() {
        // XCUITest waits for the app to quiesce after every event, so each
        // navigation push / sheet / tab switch otherwise pays its full
        // animation duration. Any -uitest-* flag marks a UI-test launch;
        // relaunches that need no other flag pass -uitest-disable-animations.
        if CommandLine.arguments.contains(where: { $0.hasPrefix("-uitest") }) {
            UIView.setAnimationsEnabled(false)
        }
        let offlineMedia = CommandLine.arguments.contains("-uitest-offline-media")
        mediaStore = ExerciseMediaStore(isNetworkDisabled: offlineMedia)
        if offlineMedia {
            // A GIF cached by an earlier (online) run would defeat the
            // deterministic degraded state the flag exists to produce.
            try? FileManager.default.removeItem(at: mediaStore.cacheDirectory)
        }
        // Either AI launch hook stubs the whole AI stack: both features
        // share one key store, so a test that stubs one must not leave the
        // other reading the real Keychain.
        if let scenario = Self.uiTestScenario(for: "-uitest-ai") ?? Self.uiTestScenario(for: "-uitest-photo-match") {
            let store = InMemoryAPIKeyStore(key: scenario == "no-key" ? nil : "uitest-stub-key")
            aiKeyStore = store
            aiSuggestionService = StubSuggestionService.uiTestService(scenario: scenario)
            aiPhotoMatchService = StubPhotoMatchService.uiTestService(scenario: scenario)
        } else {
            let store = KeychainAPIKeyStore()
            aiKeyStore = store
            aiSuggestionService = OpenRouterSuggestionService(keyStore: store)
            aiPhotoMatchService = OpenRouterPhotoMatchService(keyStore: store)
        }
    }

    /// The value following `flag` in the launch arguments, e.g. "success"
    /// for `-uitest-ai success`.
    private static func uiTestScenario(for flag: String) -> String? {
        let arguments = CommandLine.arguments
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }

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
                // tests never inherit renames from a previous run. Wiping and
                // reseeding all ~1300 Exercise rows here dominated every
                // UI-test launch; instead drop custom exercises and re-align
                // edited ones, parsing the catalog only when edits exist.
                try? container.mainContext.delete(model: Exercise.self, where: #Predicate { $0.isCustom })
                try? CatalogSeeder.restorePristineCatalog(context: container.mainContext)
                try? container.mainContext.save()
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
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(\.apiKeyStore, aiKeyStore)
                .environment(\.routineSuggestionService, aiSuggestionService)
                .environment(\.photoMatchService, aiPhotoMatchService)
                .environment(\.exerciseMediaStore, mediaStore)
        }
        .modelContainer(sharedModelContainer)
    }
}

/// Inserts deterministic saved sessions for UI tests (`-uitest-seed`,
/// normally combined with `-uitest-reset`): today with Barbell Bench Press
/// and Run, plus a Barbell Full Squat-only session three days earlier.
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
        let bench = WorkoutSeries(order: 0, exercise: exercise(withId: "gv0025"), reps: 10, weightKg: 40)
        bench.session = todaySession
        context.insert(bench)
        let run = WorkoutSeries(order: 1, exercise: exercise(withId: "gv0685"), durationSeconds: 900)
        run.session = todaySession
        context.insert(run)

        let earlierSession = WorkoutSession(date: calendar.date(byAdding: .day, value: -3, to: today) ?? today)
        context.insert(earlierSession)
        let squat = WorkoutSeries(order: 0, exercise: exercise(withId: "gv0043"), reps: 8, weightKg: 70)
        squat.session = earlierSession
        context.insert(squat)

        try context.save()
    }
}
