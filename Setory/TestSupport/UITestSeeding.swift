//
//  UITestSeeding.swift
//  Setory
//
//  Inserts deterministic saved sessions for UI tests (`-uitest-seed`,
//  normally combined with `-uitest-reset`): today with Barbell Bench Press
//  and Run, plus a Barbell Full Squat-only session three days earlier.
//

#if DEBUG

import Foundation
import SwiftData

enum UITestSeeding {
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

#endif
