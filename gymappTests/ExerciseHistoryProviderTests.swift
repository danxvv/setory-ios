//
//  ExerciseHistoryProviderTests.swift
//  gymappTests
//

import Foundation
import SwiftData
import Testing
@testable import gymapp

struct ExerciseHistoryProviderTests {
    private let context: ModelContext
    private let bench: Exercise
    private let pushUp: Exercise
    private let run: Exercise

    init() throws {
        let schema = Schema([Exercise.self, WorkoutSession.self, WorkoutSeries.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        context = ModelContext(try ModelContainer(for: schema, configurations: [config]))
        bench = Exercise(id: "bench-press", name: "Bench Press", category: .strength, primaryMuscles: [.chest])
        pushUp = Exercise(id: "push-up", name: "Push-Up", category: .strength, primaryMuscles: [.chest])
        run = Exercise(id: "treadmill-run", name: "Treadmill Run", category: .cardio, primaryMuscles: [.fullBody])
        context.insert(bench)
        context.insert(pushUp)
        context.insert(run)
    }

    /// Creates a saved session `daysAgo` with the given series specs.
    @discardableResult
    private func addSession(
        daysAgo: Int,
        series: [(exercise: Exercise, reps: Int?, weightKg: Double?, durationSeconds: Int?)]
    ) -> WorkoutSession {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: .now)!
        let session = WorkoutSession(date: date)
        context.insert(session)
        for (index, spec) in series.enumerated() {
            let entry = WorkoutSeries(
                order: index,
                exercise: spec.exercise,
                reps: spec.reps,
                weightKg: spec.weightKg,
                durationSeconds: spec.durationSeconds
            )
            entry.session = session
            context.insert(entry)
        }
        return session
    }

    private func allSeries() throws -> [WorkoutSeries] {
        try context.fetch(FetchDescriptor<WorkoutSeries>())
    }

    @Test func neverPerformedReturnsNil() throws {
        addSession(daysAgo: 0, series: [(pushUp, 12, nil, nil)])

        let summary = ExerciseHistoryProvider.summary(for: bench, in: try allSeries())

        #expect(summary == nil)
    }

    @Test func strengthBestSetIsHeaviestWeightWithRepsTieBreak() throws {
        addSession(daysAgo: 1, series: [
            (bench, 10, 40, nil),
            (bench, 8, 60, nil),
            (bench, 12, 60, nil),
        ])

        let summary = try #require(ExerciseHistoryProvider.summary(for: bench, in: try allSeries()))

        #expect(summary.bestSet.weightKg == 60)
        #expect(summary.bestSet.reps == 12)
    }

    @Test func bodyweightStrengthFallsBackToMostReps() throws {
        addSession(daysAgo: 1, series: [
            (pushUp, 15, nil, nil),
            (pushUp, 22, nil, nil),
        ])

        let summary = try #require(ExerciseHistoryProvider.summary(for: pushUp, in: try allSeries()))

        #expect(summary.bestSet.reps == 22)
    }

    @Test func cardioBestSetIsLongestDuration() throws {
        addSession(daysAgo: 2, series: [(run, nil, nil, 900)])
        addSession(daysAgo: 1, series: [(run, nil, nil, 1500)])

        let summary = try #require(ExerciseHistoryProvider.summary(for: run, in: try allSeries()))

        #expect(summary.bestSet.durationSeconds == 1500)
    }

    @Test func lastPerformedIsMostRecentSessionDate() throws {
        let older = addSession(daysAgo: 5, series: [(bench, 10, 40, nil)])
        let newer = addSession(daysAgo: 1, series: [(bench, 10, 42.5, nil)])

        let summary = try #require(ExerciseHistoryProvider.summary(for: bench, in: try allSeries()))

        #expect(summary.lastPerformed == newer.date)
        #expect(summary.lastPerformed != older.date)
    }

    @Test func recentSessionsCapAtFiveNewestFirst() throws {
        for day in 1...7 {
            addSession(daysAgo: day, series: [(bench, 10, Double(day), nil)])
        }

        let summary = try #require(ExerciseHistoryProvider.summary(for: bench, in: try allSeries()))

        #expect(summary.recentSessions.count == 5)
        let dates = summary.recentSessions.map(\.date)
        #expect(dates == dates.sorted(by: >))
        // Sessions of other exercises don't leak in.
        #expect(summary.recentSessions.allSatisfy { session in
            session.series.allSatisfy { $0.exercise?.id == bench.id }
        })
    }

    @Test func onlyThisExercisesSeriesAppearInSessions() throws {
        addSession(daysAgo: 1, series: [
            (bench, 10, 40, nil),
            (pushUp, 20, nil, nil),
            (bench, 8, 45, nil),
        ])

        let summary = try #require(ExerciseHistoryProvider.summary(for: bench, in: try allSeries()))

        #expect(summary.recentSessions.count == 1)
        #expect(summary.recentSessions[0].series.count == 2)
        #expect(summary.recentSessions[0].series.map(\.order) == [0, 2])
    }
}
