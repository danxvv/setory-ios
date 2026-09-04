//
//  RoutineSummaryTests.swift
//  gymappTests
//
//  Session summary data shown on the Routines screens: series count,
//  exercise-name aggregation, muscles-worked aggregation, and the
//  missing-exercise fallback.
//

import Foundation
import SwiftData
import Testing
@testable import gymapp

struct RoutineSummaryTests {
    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Exercise.self, WorkoutSession.self, WorkoutSeries.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private func addSeries(
        _ exercise: Exercise?,
        to session: WorkoutSession,
        order: Int,
        context: ModelContext
    ) {
        let series = WorkoutSeries(order: order, exercise: exercise, reps: 10)
        series.session = session
        context.insert(series)
    }

    @Test func exerciseNamesAreUniqueAndInSeriesOrder() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let squat = Exercise(id: "squat", name: "Squat", category: .strength, primaryMuscles: [.quads])
        let bench = Exercise(id: "bench-press", name: "Bench Press", category: .strength, primaryMuscles: [.chest])
        context.insert(squat)
        context.insert(bench)

        let session = WorkoutSession(date: .now)
        context.insert(session)
        addSeries(squat, to: session, order: 0, context: context)
        addSeries(bench, to: session, order: 1, context: context)
        addSeries(squat, to: session, order: 2, context: context)
        try context.save()

        #expect(session.series.count == 3)
        #expect(session.localizedExerciseNames == ["Squat", "Bench Press"])
    }

    @Test func musclesWorkedAggregatesUniquePrimaryMuscles() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let lunge = Exercise(id: "lunge", name: "Lunge", category: .strength, primaryMuscles: [.quads, .glutes])
        let squat = Exercise(
            id: "squat",
            name: "Squat",
            category: .strength,
            primaryMuscles: [.quads],
            secondaryMuscles: [.hamstrings]
        )
        let run = Exercise(id: "treadmill-run", name: "Treadmill Run", category: .cardio, primaryMuscles: [.fullBody])
        context.insert(lunge)
        context.insert(squat)
        context.insert(run)

        let session = WorkoutSession(date: .now)
        context.insert(session)
        addSeries(lunge, to: session, order: 0, context: context)
        addSeries(squat, to: session, order: 1, context: context)
        addSeries(run, to: session, order: 2, context: context)
        try context.save()

        // Deduplicated, in series order; secondary muscles are not included.
        #expect(session.musclesWorked == [.quads, .glutes, .fullBody])
    }

    @Test func seriesWithoutExerciseAreCountedButExcludedFromSummaries() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let bench = Exercise(id: "bench-press", name: "Bench Press", category: .strength, primaryMuscles: [.chest])
        context.insert(bench)

        let session = WorkoutSession(date: .now)
        context.insert(session)
        addSeries(bench, to: session, order: 0, context: context)
        addSeries(nil, to: session, order: 1, context: context)
        try context.save()

        #expect(session.series.count == 2)
        #expect(session.orderedSeries.count == 2)
        #expect(session.localizedExerciseNames == ["Bench Press"])
        #expect(session.musclesWorked == [.chest])
    }

    @Test func emptySessionHasEmptySummaries() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let session = WorkoutSession(date: .now)
        context.insert(session)
        try context.save()

        #expect(session.localizedExerciseNames.isEmpty)
        #expect(session.musclesWorked.isEmpty)
    }
}
