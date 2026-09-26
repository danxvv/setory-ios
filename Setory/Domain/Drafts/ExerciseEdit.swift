//
//  ExerciseEdit.swift
//  Setory
//
//  The normalized result of the exercise edit form: what would be written if
//  the user saves. A value type with no localization of its own — the form
//  resolves the displayed text and hands the final values in — so the write
//  is testable without a locale or a view.
//

import Foundation

struct ExerciseEdit: Equatable {
    var name: String
    var category: ExerciseCategory
    /// Primary muscles in canonical `Muscle.allCases` order.
    var primaryMuscles: [Muscle]
    /// Secondary muscles in canonical order, excluding any already primary.
    var secondaryMuscles: [Muscle]
    var summary: String
    var instructionSteps: [String]

    /// A name and at least one primary muscle are required, matching the
    /// form's Save button state.
    var isValid: Bool {
        !name.isEmpty && !primaryMuscles.isEmpty
    }

    /// Normalizes raw form input: trims the name and summary, orders the
    /// muscle selections canonically, drops muscles that are both primary and
    /// secondary from the secondary list, and drops blank instruction steps.
    init(
        name: String,
        category: ExerciseCategory,
        primarySelection: Set<Muscle>,
        secondarySelection: Set<Muscle>,
        summary: String,
        steps: [String]
    ) {
        self.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        self.category = category
        self.primaryMuscles = Muscle.allCases.filter(primarySelection.contains)
        self.secondaryMuscles = Muscle.allCases.filter {
            secondarySelection.contains($0) && !primarySelection.contains($0)
        }
        self.summary = summary.trimmingCharacters(in: .whitespacesAndNewlines)
        self.instructionSteps = steps
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
