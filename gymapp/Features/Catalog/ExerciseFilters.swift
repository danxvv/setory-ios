//
//  ExerciseFilters.swift
//  gymapp
//
//  The filter selection and pipeline behind the exercise library and the
//  exercise pickers. Value type with no view dependencies, so the filter
//  behavior unit-tests without any UI; ExerciseFilterBar renders it.
//

import Foundation

/// Active filter selection plus the shared filter pipeline.
struct ExerciseFilters: Equatable {
    var muscle: Muscle?
    var equipment: Equipment?

    var isActive: Bool { muscle != nil || equipment != nil }

    /// Case- and diacritic-insensitive search (see Exercise.matchesSearch)
    /// combined with the active filters. Filtering runs on locale-independent
    /// raw values, so a filtered set is identical in every language — only
    /// its ordering localizes, via the callers' sort.
    /// Preserves the input order (callers sort).
    func apply(to exercises: [Exercise], searchText: String) -> [Exercise] {
        var result = exercises
        if let muscle {
            result = result.filter { $0.primaryMuscles.contains(muscle) }
        }
        if let equipment {
            result = result.filter { $0.equipment == equipment }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.matchesSearch(searchText) }
        }
        return result
    }
}
