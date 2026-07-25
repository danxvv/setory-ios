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
    /// combined with the active filters. Muscle and equipment filtering runs
    /// on locale-independent raw values, so those results are identical in
    /// every language; only search consults the display vocabulary, and only
    /// the ordering localizes, via the callers' sort.
    /// Preserves the input order (callers sort).
    ///
    /// `languageCode` defaults to the device language so view call sites read
    /// unchanged; tests pass it explicitly so results don't depend on the
    /// test host's configured language.
    func apply(
        to exercises: [Exercise],
        searchText: String,
        languageCode: String = Exercise.contentLanguageCode
    ) -> [Exercise] {
        var result = exercises
        if let muscle {
            result = result.filter { $0.primaryMuscles.contains(muscle) }
        }
        if let equipment {
            result = result.filter { $0.equipment == equipment }
        }
        if !searchText.isEmpty {
            result = result.filter { $0.matchesSearch(searchText, languageCode: languageCode) }
        }
        return result
    }
}
