//
//  ProgressStatsProviderTests.swift
//  gymappTests
//

import Foundation
import SwiftData
import Testing
@testable import gymapp

struct ProgressStatsProviderTests {
    private let context: ModelContext
    private let bench: Exercise
    private let row: Exercise
    private let pushUp: Exercise
    private let squat: Exercise
    private let run: Exercise

    /// Gregorian, Monday-first weeks, machine time zone. The time zone must
    /// match `Calendar.current` because `WorkoutSession` normalizes dates to
    /// the local start of day; week arithmetic is otherwise pinned.
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        return calendar
    }

    /// Wednesday 2026-06-17 at noon — safely inside its week and month.
    private var now: Date {
        date(2026, 6, 17)
    }

    init() throws {
        let schema = Schema([Exercise.self, WorkoutSession.self, WorkoutSeries.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        context = ModelContext(try ModelContainer(for: schema, configurations: [config]))
        bench = Exercise(
            id: "bench-press", name: "Bench Press", category: .strength,
            primaryMuscles: [.chest], secondaryMuscles: [.triceps]
        )
        row = Exercise(id: "barbell-row", name: "Barbell Row", category: .strength, primaryMuscles: [.back, .biceps])
        pushUp = Exercise(id: "push-up", name: "Push-Up", category: .strength, primaryMuscles: [.chest])
        squat = Exercise(id: "squat", name: "Squat", category: .strength, primaryMuscles: [.quads])
        run = Exercise(id: "treadmill-run", name: "Treadmill Run", category: .cardio, primaryMuscles: [.fullBody])
        for exercise in [bench, row, pushUp, squat, run] {
            context.insert(exercise)
        }
    }

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    @discardableResult
    private func addSession(
        on date: Date,
        series: [(exercise: Exercise, reps: Int?, weightKg: Double?, durationSeconds: Int?)]
    ) -> WorkoutSession {
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

    private func allSessions() throws -> [WorkoutSession] {
        try context.fetch(FetchDescriptor<WorkoutSession>())
    }

    private func allSeries() throws -> [WorkoutSeries] {
        try context.fetch(FetchDescriptor<WorkoutSeries>())
    }

    // MARK: - Weekly session counts

    @Test func weeklyCountsZeroFillAndBucketAcrossMonthBoundaries() throws {
        addSession(on: date(2026, 6, 17), series: [(bench, 10, 40, nil)])
        addSession(on: date(2026, 6, 16), series: [(squat, 8, 70, nil)])
        addSession(on: date(2026, 6, 10), series: [(bench, 10, 42.5, nil)])
        addSession(on: date(2026, 5, 6), series: [(run, nil, nil, 900)])
        addSession(on: date(2026, 4, 22), series: [(bench, 10, 40, nil)]) // outside the 8-week window

        let buckets = ProgressStatsProvider.weeklySessionCounts(
            sessions: try allSessions(), calendar: calendar, now: now
        )

        #expect(buckets.count == 8)
        // Weeks are Monday-first: Apr 27 ... Jun 15, oldest first.
        #expect(buckets.first?.weekStart == calendar.startOfDay(for: date(2026, 4, 27)))
        #expect(buckets.last?.weekStart == calendar.startOfDay(for: date(2026, 6, 15)))
        #expect(buckets.map(\.sessionCount) == [0, 1, 0, 0, 0, 0, 1, 2])
    }

    @Test func weeklyCountsWithNoSessionsAreAllZero() throws {
        let buckets = ProgressStatsProvider.weeklySessionCounts(
            sessions: [], calendar: calendar, now: now
        )

        #expect(buckets.count == 8)
        #expect(buckets.allSatisfy { $0.sessionCount == 0 })
    }

    // MARK: - Headline counts

    @Test func headlineCountsSplitWeekAndMonth() throws {
        addSession(on: date(2026, 6, 17), series: [(bench, 10, 40, nil), (bench, 8, 45, nil)])
        addSession(on: date(2026, 6, 15), series: [(squat, 8, 70, nil)])
        addSession(on: date(2026, 6, 3), series: [(run, nil, nil, 900)])
        addSession(on: date(2026, 5, 20), series: [(bench, 10, 40, nil), (squat, 5, 90, nil), (run, nil, nil, 600)])

        let counts = ProgressStatsProvider.headlineCounts(
            sessions: try allSessions(), calendar: calendar, now: now
        )

        #expect(counts.weekSessions == 2)
        #expect(counts.weekSeries == 3)
        #expect(counts.monthSessions == 3)
        #expect(counts.monthSeries == 4)
    }

    // MARK: - Muscle balance

    @Test func muscleBalanceCountsPrimaryMusclesOnlySortedDescending() throws {
        addSession(on: date(2026, 6, 17), series: [
            (bench, 10, 40, nil),
            (bench, 8, 45, nil),
            (row, 10, 30, nil),
        ])

        let counts = ProgressStatsProvider.muscleBalance(
            series: try allSeries(), period: .week, calendar: calendar, now: now
        )

        #expect(counts.map(\.muscle) == [.chest, .back, .biceps])
        #expect(counts.map(\.seriesCount) == [2, 1, 1])
        // Bench's secondary muscle (triceps) must not be counted.
        #expect(!counts.contains { $0.muscle == .triceps })
    }

    @Test func muscleBalancePeriodFiltersWeekVersusMonth() throws {
        addSession(on: date(2026, 6, 17), series: [(bench, 10, 40, nil)])
        addSession(on: date(2026, 6, 10), series: [(squat, 8, 70, nil)]) // same month, previous week

        let week = ProgressStatsProvider.muscleBalance(
            series: try allSeries(), period: .week, calendar: calendar, now: now
        )
        let month = ProgressStatsProvider.muscleBalance(
            series: try allSeries(), period: .month, calendar: calendar, now: now
        )

        #expect(week.map(\.muscle) == [.chest])
        #expect(Set(month.map(\.muscle)) == [.chest, .quads])
    }

    @Test func muscleBalanceEmptyPeriodReturnsNothing() throws {
        addSession(on: date(2026, 5, 20), series: [(bench, 10, 40, nil)])

        let counts = ProgressStatsProvider.muscleBalance(
            series: try allSeries(), period: .week, calendar: calendar, now: now
        )

        #expect(counts.isEmpty)
    }

    // MARK: - Progression

    @Test func neverPerformedReturnsNil() throws {
        addSession(on: date(2026, 6, 17), series: [(pushUp, 12, nil, nil)])

        #expect(ProgressStatsProvider.progression(for: bench, in: try allSeries()) == nil)
    }

    @Test func weightedStrengthProgressionChartsMaxWeightAndVolume() throws {
        addSession(on: date(2026, 6, 12), series: [(bench, 10, 40, nil)])
        addSession(on: date(2026, 6, 14), series: [(bench, 8, 60, nil), (bench, 12, 60, nil)])
        addSession(on: date(2026, 6, 16), series: [(bench, 10, 50, nil)])

        let progression = try #require(ProgressStatsProvider.progression(for: bench, in: try allSeries()))

        #expect(progression.metric == .weight)
        #expect(progression.points.map(\.value) == [40, 60, 50])
        #expect(progression.points.map(\.volume) == [400, 1200, 500])
        #expect(progression.points.map(\.isPersonalRecord) == [true, true, false])
        #expect(progression.points.map(\.date) == progression.points.map(\.date).sorted())
        #expect(progression.bestSet.weightKg == 60)
        #expect(progression.bestSet.reps == 12)
    }

    @Test func repsTieBreakCountsAsPersonalRecord() throws {
        addSession(on: date(2026, 6, 12), series: [(bench, 10, 40, nil)])
        addSession(on: date(2026, 6, 14), series: [(bench, 12, 40, nil)])

        let progression = try #require(ProgressStatsProvider.progression(for: bench, in: try allSeries()))

        #expect(progression.points.map(\.isPersonalRecord) == [true, true])
    }

    @Test func weightlessSessionsAreOmittedFromWeightProgression() throws {
        addSession(on: date(2026, 6, 12), series: [(bench, 10, 40, nil)])
        addSession(on: date(2026, 6, 14), series: [(bench, 15, nil, nil)]) // deload day, no weight
        addSession(on: date(2026, 6, 16), series: [(bench, 10, 50, nil)])

        let progression = try #require(ProgressStatsProvider.progression(for: bench, in: try allSeries()))

        #expect(progression.metric == .weight)
        #expect(progression.points.count == 2)
        #expect(progression.points.map(\.value) == [40, 50])
    }

    @Test func neverWeightedStrengthUsesRepsMetric() throws {
        addSession(on: date(2026, 6, 14), series: [(pushUp, 15, nil, nil), (pushUp, 22, nil, nil)])
        addSession(on: date(2026, 6, 16), series: [(pushUp, 20, nil, nil)])

        let progression = try #require(ProgressStatsProvider.progression(for: pushUp, in: try allSeries()))

        #expect(progression.metric == .reps)
        #expect(progression.points.map(\.value) == [22, 20])
        #expect(progression.points.map(\.isPersonalRecord) == [true, false])
        #expect(progression.bestSet.reps == 22)
    }

    @Test func cardioUsesDurationMetric() throws {
        addSession(on: date(2026, 6, 14), series: [(run, nil, nil, 900)])
        addSession(on: date(2026, 6, 16), series: [(run, nil, nil, 1500)])

        let progression = try #require(ProgressStatsProvider.progression(for: run, in: try allSeries()))

        #expect(progression.metric == .duration)
        #expect(progression.points.map(\.value) == [900, 1500])
        #expect(progression.points.map(\.isPersonalRecord) == [true, true])
        #expect(progression.bestSet.durationSeconds == 1500)
    }

    @Test func singleSessionProducesOnePoint() throws {
        addSession(on: date(2026, 6, 16), series: [(bench, 10, 40, nil)])

        let progression = try #require(ProgressStatsProvider.progression(for: bench, in: try allSeries()))

        #expect(progression.points.count == 1)
        #expect(progression.points[0].isPersonalRecord)
    }

    @Test func otherExercisesSeriesDoNotLeakIn() throws {
        addSession(on: date(2026, 6, 16), series: [
            (bench, 10, 40, nil),
            (squat, 8, 120, nil),
        ])

        let progression = try #require(ProgressStatsProvider.progression(for: bench, in: try allSeries()))

        #expect(progression.points.map(\.value) == [40])
        #expect(progression.bestSet.weightKg == 40)
    }
}
