//
//  ExerciseCategory.swift
//  Setory
//

import Foundation

/// How an exercise is measured: reps (+ optional weight) or elapsed time.
enum ExerciseCategory: String, Codable, CaseIterable, Sendable {
    case strength
    case cardio
}
