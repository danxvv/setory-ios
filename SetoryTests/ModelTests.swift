//
//  ModelTests.swift
//  SetoryTests
//

import Foundation
import SwiftData
import Testing
@testable import Setory

struct ModelTests {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Exercise.self, WorkoutSession.self, WorkoutSeries.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    @Test func exerciseCreation() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let exercise = Exercise(
            id: "bench-press",
            name: "Bench Press",
            category: .strength,
            primaryMuscles: [.chest],
            secondaryMuscles: [.triceps, .shoulders]
        )
        context.insert(exercise)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<Exercise>())
        #expect(fetched.count == 1)
        #expect(fetched.first?.name == "Bench Press")
        #expect(fetched.first?.category == .strength)
        #expect(fetched.first?.primaryMuscles == [.chest])
        #expect(fetched.first?.secondaryMuscles == [.triceps, .shoulders])
    }

    @Test func sessionDateIsNormalizedToStartOfDay() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let calendar = Calendar.current
        let midAfternoon = calendar.date(
            bySettingHour: 15, minute: 42, second: 7, of: .now
        )!
        let session = WorkoutSession(date: midAfternoon)
        context.insert(session)
        try context.save()

        #expect(session.date == calendar.startOfDay(for: midAfternoon))
    }

    @Test func sessionSeriesKeepInsertionOrder() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let squat = Exercise(id: "squat", name: "Squat", category: .strength, primaryMuscles: [.quads])
        let run = Exercise(id: "treadmill-run", name: "Treadmill Run", category: .cardio, primaryMuscles: [.fullBody])
        context.insert(squat)
        context.insert(run)

        let session = WorkoutSession(date: .now)
        context.insert(session)
        let first = WorkoutSeries(order: 0, exercise: squat, reps: 10, weightKg: 60)
        let second = WorkoutSeries(order: 1, exercise: squat, reps: 8, weightKg: 70)
        let third = WorkoutSeries(order: 2, exercise: run, durationSeconds: 900)
        first.session = session
        second.session = session
        third.session = session
        context.insert(first)
        context.insert(second)
        context.insert(third)
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<WorkoutSession>()).first
        let ordered = try #require(fetched?.orderedSeries)
        #expect(ordered.map(\.order) == [0, 1, 2])
        #expect(ordered[0].reps == 10)
        #expect(ordered[0].weightKg == 60)
        #expect(ordered[2].exercise?.category == .cardio)
        #expect(ordered[2].durationSeconds == 900)
    }

    @Test func onlyOneSessionPerDay() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let calendar = Calendar.current
        let morning = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: .now)!
        let evening = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: .now)!

        context.insert(WorkoutSession(date: morning))
        try context.save()
        // Same calendar day → same normalized unique date → upsert, not a duplicate.
        context.insert(WorkoutSession(date: evening))
        try context.save()

        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        #expect(sessions.count == 1)
    }
}
