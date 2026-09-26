//
//  ProgressStatsProvider.swift
//  Setory
//

import Foundation

/// Read-only aggregation for the Progress tab: workouts per week, series
/// volume per muscle, and per-exercise progression time series.
/// Pure functions over already-fetched models, so unit tests need no UI.
/// Calendar and reference date are injectable so week/month bucketing is
/// deterministic under test.
enum ProgressStatsProvider {

    // MARK: - Training overview

    struct WeekBucket: Identifiable {
        var id: Date { weekStart }
        let weekStart: Date
        let sessionCount: Int
    }

    /// Sessions per calendar week for the `weeks` most recent weeks,
    /// oldest first and ending with the week containing `now`. Weeks
    /// without sessions appear with a count of zero.
    static func weeklySessionCounts(
        sessions: [WorkoutSession],
        weeks: Int = 8,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> [WeekBucket] {
        guard weeks > 0,
              let currentWeek = calendar.dateInterval(of: .weekOfYear, for: now)
        else { return [] }

        var starts: [Date] = []
        for offset in (1 - weeks)...0 {
            if let start = calendar.date(byAdding: .weekOfYear, value: offset, to: currentWeek.start) {
                starts.append(start)
            }
        }
        var counts: [Date: Int] = [:]
        for session in sessions {
            if let week = calendar.dateInterval(of: .weekOfYear, for: session.date) {
                counts[week.start, default: 0] += 1
            }
        }
        return starts.map { WeekBucket(weekStart: $0, sessionCount: counts[$0] ?? 0) }
    }

    struct HeadlineCounts {
        let weekSessions: Int
        let weekSeries: Int
        let monthSessions: Int
        let monthSeries: Int
    }

    /// Session and series totals for the calendar week and month containing `now`.
    static func headlineCounts(
        sessions: [WorkoutSession],
        calendar: Calendar = .current,
        now: Date = .now
    ) -> HeadlineCounts {
        func totals(in interval: DateInterval?) -> (sessions: Int, series: Int) {
            guard let interval else { return (0, 0) }
            let matching = sessions.filter { interval.contains($0.date) }
            return (matching.count, matching.reduce(0) { $0 + $1.series.count })
        }
        let week = totals(in: calendar.dateInterval(of: .weekOfYear, for: now))
        let month = totals(in: calendar.dateInterval(of: .month, for: now))
        return HeadlineCounts(
            weekSessions: week.sessions,
            weekSeries: week.series,
            monthSessions: month.sessions,
            monthSeries: month.series
        )
    }

    // MARK: - Muscle balance

    enum StatsPeriod: CaseIterable {
        case week, month
    }

    struct MuscleCount: Identifiable {
        var id: Muscle { muscle }
        let muscle: Muscle
        let seriesCount: Int
    }

    /// Series per muscle within the calendar week/month containing `now`.
    /// Each series counts once toward every primary muscle of its exercise;
    /// secondary muscles are excluded. Muscles with no series are omitted.
    /// Sorted by count descending, ties broken by raw value for stability.
    static func muscleBalance(
        series allSeries: [WorkoutSeries],
        period: StatsPeriod,
        calendar: Calendar = .current,
        now: Date = .now
    ) -> [MuscleCount] {
        let component: Calendar.Component = period == .week ? .weekOfYear : .month
        guard let interval = calendar.dateInterval(of: component, for: now) else { return [] }

        var counts: [Muscle: Int] = [:]
        for series in allSeries {
            guard let date = series.session?.date, interval.contains(date) else { continue }
            for muscle in series.exercise?.primaryMuscles ?? [] {
                counts[muscle, default: 0] += 1
            }
        }
        return counts
            .map { MuscleCount(muscle: $0.key, seriesCount: $0.value) }
            .sorted {
                if $0.seriesCount != $1.seriesCount { return $0.seriesCount > $1.seriesCount }
                return $0.muscle.rawValue < $1.muscle.rawValue
            }
    }

    // MARK: - Exercise progression

    enum ProgressionMetric {
        /// Strength with at least one weighted set: max weight + session volume.
        case weight
        /// Strength never logged with a weight: max repetitions.
        case reps
        /// Cardio: longest duration.
        case duration
    }

    struct ProgressionPoint: Identifiable {
        var id: Date { date }
        let date: Date
        /// Metric value: kg for `.weight`, reps for `.reps`, seconds for `.duration`.
        let value: Double
        /// Session volume (Σ reps × weight over weighted sets); `.weight` only.
        let volume: Double?
        /// True when this session improved on every prior session's best set.
        let isPersonalRecord: Bool
    }

    struct Progression {
        let metric: ProgressionMetric
        /// One point per charted session, oldest first. For `.weight`,
        /// sessions with no weighted set are omitted (not plotted as zero).
        let points: [ProgressionPoint]
        /// All-time best set, same ordering as the exercise detail screen.
        let bestSet: WorkoutSeries
    }

    /// Nil when the exercise has never been performed in a saved session.
    static func progression(
        for exercise: Exercise,
        in allSeries: [WorkoutSeries]
    ) -> Progression? {
        let bySession = Dictionary(
            grouping: allSeries.filter { $0.exercise?.id == exercise.id }
        ) { $0.session?.date }
            .compactMap { date, series -> (date: Date, series: [WorkoutSeries])? in
                guard let date else { return nil }
                return (date, series)
            }
            .sorted { $0.date < $1.date }
        let attached = bySession.flatMap(\.series)
        guard let bestSet = ExerciseHistoryProvider.bestSet(in: attached, category: exercise.category)
        else { return nil }

        let metric: ProgressionMetric = switch exercise.category {
        case .cardio: .duration
        case .strength: attached.contains { $0.weightKg != nil } ? .weight : .reps
        }

        var points: [ProgressionPoint] = []
        // Best-set ordering per session as a comparable pair: weight then
        // reps for `.weight`; reps or duration alone otherwise.
        var runningBest: (primary: Double, secondary: Double)?
        for (date, series) in bySession {
            let sessionBest: (primary: Double, secondary: Double)
            let value: Double
            var volume: Double?
            switch metric {
            case .weight:
                let weighted = series.filter { $0.weightKg != nil }
                guard let top = weighted.max(by: { lhs, rhs in
                    if lhs.weightKg != rhs.weightKg { return (lhs.weightKg ?? 0) < (rhs.weightKg ?? 0) }
                    return (lhs.reps ?? 0) < (rhs.reps ?? 0)
                }) else { continue }
                sessionBest = (top.weightKg ?? 0, Double(top.reps ?? 0))
                value = top.weightKg ?? 0
                volume = weighted.reduce(0) { $0 + Double($1.reps ?? 0) * ($1.weightKg ?? 0) }
            case .reps:
                let top = series.map { $0.reps ?? 0 }.max() ?? 0
                sessionBest = (Double(top), 0)
                value = Double(top)
            case .duration:
                let top = series.map { $0.durationSeconds ?? 0 }.max() ?? 0
                sessionBest = (Double(top), 0)
                value = Double(top)
            }

            let isRecord: Bool
            if let current = runningBest {
                isRecord = sessionBest.primary > current.primary
                    || (sessionBest.primary == current.primary && sessionBest.secondary > current.secondary)
            } else {
                isRecord = true
            }
            if isRecord { runningBest = sessionBest }
            points.append(ProgressionPoint(date: date, value: value, volume: volume, isPersonalRecord: isRecord))
        }
        guard !points.isEmpty else { return nil }

        return Progression(metric: metric, points: points, bestSet: bestSet)
    }
}
