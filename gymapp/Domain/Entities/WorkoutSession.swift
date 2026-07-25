//
//  WorkoutSession.swift
//  gymapp
//

import Foundation
import SwiftData

@Model
final class WorkoutSession {
    /// Normalized to start-of-day; one session per calendar day.
    @Attribute(.unique) var date: Date
    var finishedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSeries.session)
    var series: [WorkoutSeries]

    /// Series in the order the user added them.
    var orderedSeries: [WorkoutSeries] {
        series.sorted { $0.order < $1.order }
    }

    /// Names of the exercises involved, deduplicated, in series order.
    /// Series without an exercise are skipped. Canonical (stored) names;
    /// views should display `localizedExerciseNames` (see ExerciseDisplay).
    var exerciseNames: [String] {
        var seen = Set<String>()
        var names: [String] = []
        for series in orderedSeries {
            if let name = series.exercise?.name, seen.insert(name).inserted {
                names.append(name)
            }
        }
        return names
    }

    /// Primary muscles targeted across the session's exercises, deduplicated,
    /// in series order. Series without an exercise contribute nothing.
    var musclesWorked: [Muscle] {
        var seen = Set<Muscle>()
        var muscles: [Muscle] = []
        for series in orderedSeries {
            for muscle in series.exercise?.primaryMuscles ?? [] where seen.insert(muscle).inserted {
                muscles.append(muscle)
            }
        }
        return muscles
    }

    init(date: Date, finishedAt: Date = .now, series: [WorkoutSeries] = []) {
        self.date = Calendar.current.startOfDay(for: date)
        self.finishedAt = finishedAt
        self.series = series
    }
}

@Model
final class WorkoutSeries {
    /// Position within the session, starting at 0.
    var order: Int
    var exercise: Exercise?
    var session: WorkoutSession?
    var reps: Int?
    var weightKg: Double?
    var durationSeconds: Int?

    init(
        order: Int,
        exercise: Exercise?,
        reps: Int? = nil,
        weightKg: Double? = nil,
        durationSeconds: Int? = nil
    ) {
        self.order = order
        self.exercise = exercise
        self.reps = reps
        self.weightKg = weightKg
        self.durationSeconds = durationSeconds
    }
}
