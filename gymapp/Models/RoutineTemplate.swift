//
//  RoutineTemplate.swift
//  gymapp
//
//  A named, reusable workout plan: an ordered list of exercises with a
//  target set count each. Mirrors the WorkoutSession/WorkoutSeries shape:
//  cascade delete to items, `order` column with an ordered accessor, and
//  optional exercise references tolerated (skipped) everywhere.
//

import Foundation
import SwiftData

@Model
final class RoutineTemplate {
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \RoutineTemplateItem.template)
    var items: [RoutineTemplateItem]

    /// Items in the order the user arranged them.
    var orderedItems: [RoutineTemplateItem] {
        items.sorted { $0.order < $1.order }
    }

    /// The items' exercises in template order, skipping missing references.
    var exercises: [Exercise] {
        orderedItems.compactMap(\.exercise)
    }

    /// Muscle coverage is derived at display time — never stored — so later
    /// exercise edits are reflected automatically.
    var primaryMusclesCovered: [Muscle] {
        Self.primaryMusclesCovered(by: exercises)
    }

    var secondaryMusclesCovered: [Muscle] {
        Self.secondaryMusclesCovered(by: exercises)
    }

    /// Union of the exercises' primary muscles in first-appearance order.
    static func primaryMusclesCovered(by exercises: [Exercise]) -> [Muscle] {
        var seen = Set<Muscle>()
        var muscles: [Muscle] = []
        for exercise in exercises {
            for muscle in exercise.primaryMuscles where seen.insert(muscle).inserted {
                muscles.append(muscle)
            }
        }
        return muscles
    }

    /// Union of the exercises' secondary muscles in first-appearance order,
    /// excluding muscles already covered as primary.
    static func secondaryMusclesCovered(by exercises: [Exercise]) -> [Muscle] {
        var seen = Set<Muscle>(primaryMusclesCovered(by: exercises))
        var muscles: [Muscle] = []
        for exercise in exercises {
            for muscle in exercise.secondaryMuscles where seen.insert(muscle).inserted {
                muscles.append(muscle)
            }
        }
        return muscles
    }

    init(name: String, createdAt: Date = .now, items: [RoutineTemplateItem] = []) {
        self.name = name
        self.createdAt = createdAt
        self.items = items
    }
}

@Model
final class RoutineTemplateItem {
    /// Valid target set counts; values outside are clamped on init.
    static let targetSetsRange = 1...10

    /// Position within the template, starting at 0.
    var order: Int
    /// How many sets the user intends to perform (1–10).
    var targetSets: Int
    var exercise: Exercise?
    var template: RoutineTemplate?

    init(order: Int, targetSets: Int = 3, exercise: Exercise?) {
        self.order = order
        self.targetSets = min(max(targetSets, Self.targetSetsRange.lowerBound), Self.targetSetsRange.upperBound)
        self.exercise = exercise
    }
}
