//
//  ExerciseHistoryProvider.swift
//  Setory
//

import Foundation

/// Read-only aggregation of the user's logged series for one exercise.
/// Pure functions over already-fetched series, so unit tests need no UI.
enum ExerciseHistoryProvider {
    struct RecentSession: Identifiable {
        var id: Date { date }
        let date: Date
        /// This exercise's series within the session, in recorded order.
        let series: [WorkoutSeries]
    }

    struct Summary {
        let lastPerformed: Date
        let bestSet: WorkoutSeries
        let recentSessions: [RecentSession]
    }

    /// Nil when the exercise has never been performed (no saved series).
    static func summary(
        for exercise: Exercise,
        in allSeries: [WorkoutSeries],
        recentLimit: Int = 5
    ) -> Summary? {
        let relevant = allSeries.filter { $0.exercise?.id == exercise.id }
        let bySessionDate = Dictionary(grouping: relevant) { $0.session?.date }
            .compactMap { date, series -> (date: Date, series: [WorkoutSeries])? in
                guard let date else { return nil }
                return (date, series.sorted { $0.order < $1.order })
            }
            .sorted { $0.date > $1.date }
        guard let latest = bySessionDate.first,
              let best = bestSet(in: bySessionDate.flatMap(\.series), category: exercise.category)
        else { return nil }

        return Summary(
            lastPerformed: latest.date,
            bestSet: best,
            recentSessions: bySessionDate.prefix(recentLimit).map {
                RecentSession(date: $0.date, series: $0.series)
            }
        )
    }

    /// Best set: strength — heaviest weight (ties broken by reps), falling
    /// back to the most reps when no set has a weight; cardio — longest
    /// duration.
    static func bestSet(in series: [WorkoutSeries], category: ExerciseCategory) -> WorkoutSeries? {
        switch category {
        case .strength:
            let weighted = series.filter { $0.weightKg != nil }
            if !weighted.isEmpty {
                return weighted.max { lhs, rhs in
                    if lhs.weightKg != rhs.weightKg {
                        return (lhs.weightKg ?? 0) < (rhs.weightKg ?? 0)
                    }
                    return (lhs.reps ?? 0) < (rhs.reps ?? 0)
                }
            }
            return series.max { ($0.reps ?? 0) < ($1.reps ?? 0) }
        case .cardio:
            return series.max { ($0.durationSeconds ?? 0) < ($1.durationSeconds ?? 0) }
        }
    }
}
