//
//  DayPlan.swift
//  gymapp
//
//  A template applied to one logging day. Lives in view state only, exactly
//  like DraftSeries: the plan is guidance, never persisted — "Finish Day"
//  saves only actually logged series.
//

import Foundation

struct DayPlan: Equatable {
    /// Snapshot of the template's name at apply time, shown as the plan
    /// section header.
    let templateName: String
    let exercises: [PlannedExercise]

    /// Stages a template as a day plan, skipping items whose exercise
    /// reference is missing. Items repeating an exercise merge into one row
    /// with their targets summed: progress is derived per exercise from the
    /// day's drafts, so separate rows for the same exercise would all count
    /// every logged set and read complete at a fraction of the volume.
    static func staged(from template: RoutineTemplate) -> DayPlan {
        var exercises: [PlannedExercise] = []
        var rowIndexByExerciseId: [String: Int] = [:]
        for item in template.orderedItems {
            guard let exercise = item.exercise else { continue }
            if let index = rowIndexByExerciseId[exercise.id] {
                exercises[index] = PlannedExercise(
                    exercise: exercises[index].exercise,
                    targetSets: exercises[index].targetSets + item.targetSets
                )
            } else {
                rowIndexByExerciseId[exercise.id] = exercises.count
                exercises.append(PlannedExercise(exercise: exercise, targetSets: item.targetSets))
            }
        }
        return DayPlan(templateName: template.name, exercises: exercises)
    }

    /// How many of the day's drafts count toward `exercise` — the plan row's
    /// "logged" side of `logged/target`.
    static func loggedSets(for exercise: Exercise, in drafts: [DraftSeries]) -> Int {
        drafts.count { $0.exercise.id == exercise.id }
    }
}

struct PlannedExercise: Identifiable, Equatable {
    let id = UUID()
    let exercise: Exercise
    let targetSets: Int
}
