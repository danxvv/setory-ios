//
//  TemplateNameSuggester.swift
//  gymapp
//
//  Proposes a template name from the exercises' dominant primary-muscle
//  profile. Pure function over already-resolved exercises, matching
//  ExerciseHistoryProvider style. The result is evaluated in the current
//  locale and offered as editable text — stored names are always plain
//  user content.
//

import Foundation

enum TemplateNameSuggester {
    private static let lowerBodyMuscles: Set<Muscle> = [.glutes, .quads, .hamstrings, .calves]

    /// Nil for an empty exercise list (or one with no primary-muscle data
    /// and no cardio majority to name).
    static func suggestedName(for exercises: [Exercise]) -> String? {
        guard !exercises.isEmpty else { return nil }

        // Tally primary muscles; each exercise votes once per primary muscle.
        var votes: [Muscle: Int] = [:]
        var appearanceOrder: [Muscle] = []
        for exercise in exercises {
            var seenForExercise = Set<Muscle>()
            for muscle in exercise.primaryMuscles where seenForExercise.insert(muscle).inserted {
                if votes[muscle] == nil {
                    appearanceOrder.append(muscle)
                }
                votes[muscle, default: 0] += 1
            }
        }

        let totalVotes = votes.values.reduce(0, +)
        let lowerBodyVotes = votes
            .filter { lowerBodyMuscles.contains($0.key) }
            .values.reduce(0, +)
        if lowerBodyVotes * 2 > totalVotes {
            return String(localized: "Leg Day")
        }
        if exercises.allSatisfy({ $0.category == .cardio }) {
            return String(localized: "Cardio")
        }

        // Top one or two muscles by votes; ties keep first-appearance order.
        let rank = Dictionary(uniqueKeysWithValues: appearanceOrder.enumerated().map { ($1, $0) })
        let ranked = appearanceOrder.sorted {
            if votes[$0] != votes[$1] {
                return votes[$0, default: 0] > votes[$1, default: 0]
            }
            return rank[$0, default: 0] < rank[$1, default: 0]
        }
        guard let top = ranked.first else { return nil }
        guard ranked.count > 1 else { return top.displayName }
        return String(localized: "\(top.displayName) & \(ranked[1].displayName)")
    }
}
