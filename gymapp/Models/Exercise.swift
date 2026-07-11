//
//  Exercise.swift
//  gymapp
//

import Foundation
import SwiftData

@Model
final class Exercise {
    /// Stable identifier from the seed catalog (e.g. "bench-press").
    @Attribute(.unique) var id: String
    var name: String
    var categoryRaw: String
    var primaryMuscleRaws: [String]
    var secondaryMuscleRaws: [String]
    /// False for seeded exercises; reserved for a future custom-exercise change.
    var isCustom: Bool
    /// Canonical (English) description of the exercise. Defaulted so stores
    /// created before this property existed migrate lightweight; the seeder
    /// backfills real content.
    var summary: String = ""
    /// Canonical (English) step-by-step instructions, in order.
    var instructionSteps: [String] = []
    /// True once the user edits this exercise. User-modified exercises render
    /// their stored text verbatim — the catalog localization tables no longer
    /// apply — and the seeder never overwrites them.
    var isUserModified: Bool = false

    /// Display name resolved through the ExerciseNames catalog by stable id.
    /// Ids without a catalog entry (e.g. custom exercises) fall back to the
    /// stored name, which stays canonical in the persistent store.
    /// User-modified exercises always show their stored name.
    var localizedName: String {
        guard !isUserModified else { return name }
        return Bundle.main.localizedString(forKey: "exercise.\(id)", value: name, table: "ExerciseNames")
    }

    /// Description resolved through the ExerciseContent catalog by stable id,
    /// falling back to the stored summary (user-modified or unknown ids).
    var localizedSummary: String {
        guard !isUserModified else { return summary }
        return Bundle.main.localizedString(forKey: "exercise.\(id).summary", value: summary, table: "ExerciseContent")
    }

    /// Instruction steps resolved through the ExerciseContent catalog by
    /// stable id and 1-based step index, falling back to the stored steps.
    var localizedInstructionSteps: [String] {
        guard !isUserModified else { return instructionSteps }
        return instructionSteps.enumerated().map { index, step in
            Bundle.main.localizedString(forKey: "exercise.\(id).step.\(index + 1)", value: step, table: "ExerciseContent")
        }
    }

    var category: ExerciseCategory {
        get { ExerciseCategory(rawValue: categoryRaw) ?? .strength }
        set { categoryRaw = newValue.rawValue }
    }

    var primaryMuscles: [Muscle] {
        get { primaryMuscleRaws.compactMap(Muscle.init(rawValue:)) }
        set { primaryMuscleRaws = newValue.map(\.rawValue) }
    }

    var secondaryMuscles: [Muscle] {
        get { secondaryMuscleRaws.compactMap(Muscle.init(rawValue:)) }
        set { secondaryMuscleRaws = newValue.map(\.rawValue) }
    }

    init(
        id: String,
        name: String,
        category: ExerciseCategory,
        primaryMuscles: [Muscle],
        secondaryMuscles: [Muscle] = [],
        isCustom: Bool = false,
        summary: String = "",
        instructionSteps: [String] = [],
        isUserModified: Bool = false
    ) {
        self.id = id
        self.name = name
        self.categoryRaw = category.rawValue
        self.primaryMuscleRaws = primaryMuscles.map(\.rawValue)
        self.secondaryMuscleRaws = secondaryMuscles.map(\.rawValue)
        self.isCustom = isCustom
        self.summary = summary
        self.instructionSteps = instructionSteps
        self.isUserModified = isUserModified
    }
}
