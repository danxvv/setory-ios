//
//  ExerciseStore.swift
//  Setory
//
//  Writes for the exercise edit form. Saving marks the exercise
//  user-modified, which freezes its text to the stored values and stops the
//  catalog seeder from touching it again (see Exercise.isUserModified) — so
//  the no-op guard in the form matters, and this store is the only place that
//  flag gets set.
//

import Foundation
import SwiftData

struct ExerciseStore: PersistenceStore {
    let context: ModelContext
    var commit: (ModelContext) throws -> Void = { try $0.save() }

    /// Applies `edit` to `exercise` and persists it, marking the exercise
    /// user-modified. Throws (after rolling back) when the save fails, so a
    /// failed edit leaves neither the values nor the flag changed.
    func save(_ edit: ExerciseEdit, to exercise: Exercise) throws {
        exercise.name = edit.name
        exercise.category = edit.category
        exercise.primaryMuscles = edit.primaryMuscles
        exercise.secondaryMuscles = edit.secondaryMuscles
        exercise.summary = edit.summary
        exercise.instructionSteps = edit.instructionSteps
        exercise.isUserModified = true
        try saveOrRollback()
    }
}
