//
//  Exercise.swift
//  gymapp
//

import Foundation
import SwiftData

@Model
final class Exercise {
    /// Stable identifier from the seed catalog (e.g. "gv0025").
    @Attribute(.unique) var id: String
    var name: String
    var categoryRaw: String
    var primaryMuscleRaws: [String]
    var secondaryMuscleRaws: [String]
    /// True for user-space exercises the seeder must never manage. Set by the
    /// legacy-catalog migration for preserved orphans; also reserved for a
    /// future custom-exercise change.
    var isCustom: Bool
    /// Canonical (English) description of the exercise. Defaulted so stores
    /// created before this property existed migrate lightweight; the seeder
    /// backfills real content.
    var summary: String = ""
    /// Canonical (English) step-by-step instructions, in order.
    var instructionSteps: [String] = []
    /// True once the user edits this exercise. User-modified exercises render
    /// their stored text verbatim — content translations no longer apply —
    /// and the seeder never overwrites them.
    var isUserModified: Bool = false
    /// Equipment raw value (Equipment). Nil for exercises without catalog
    /// equipment metadata (legacy orphans, custom exercises).
    var equipmentRaw: String? = nil
    /// Remote animation file name in the pinned dataset (e.g.
    /// "0025-EIeI8Vf.gif"). Nil means the exercise has no media; the bundled
    /// thumbnail is looked up by exercise id instead.
    var gifFileName: String? = nil
    /// Display-name translations keyed by language code ("es"). English stays
    /// canonical in `name`. Empty for custom exercises.
    var nameTranslations: [String: String] = [:]
    /// Description translations keyed by language code ("es"). English stays
    /// canonical in `summary`.
    var summaryTranslations: [String: String] = [:]
    /// Instruction-step translations keyed by language code ("es").
    var instructionTranslations: [String: [String]] = [:]

    /// An empty translation falls back rather than rendering a nameless row,
    /// which is why this guards on non-empty where the content accessors
    /// below can afford not to.
    func localizedName(languageCode: String) -> String {
        guard !isUserModified else { return name }
        if let translated = nameTranslations[languageCode], !translated.isEmpty {
            return translated
        }
        return name
    }

    /// Case- and diacritic-insensitive search match against the given
    /// language. Both the resolved name and the canonical English one are
    /// tested: the dataset vocabulary is English, so a Spanish-device user
    /// searching "bench press" — off the machine's label, or out of an AI
    /// match result — must still find it.
    func matchesSearch(_ text: String, languageCode: String) -> Bool {
        guard !text.isEmpty else { return true }
        return localizedName(languageCode: languageCode).localizedStandardContains(text)
            || name.localizedStandardContains(text)
    }

    /// Description for the given language, falling back to the canonical
    /// English summary. User-modified exercises show their stored text
    /// verbatim.
    func localizedSummary(languageCode: String) -> String {
        guard !isUserModified else { return summary }
        return summaryTranslations[languageCode] ?? summary
    }

    /// Instruction steps for the given language, falling back to the
    /// canonical English steps. User-modified exercises show their stored
    /// steps verbatim.
    func localizedInstructionSteps(languageCode: String) -> [String] {
        guard !isUserModified else { return instructionSteps }
        if let translated = instructionTranslations[languageCode], !translated.isEmpty {
            return translated
        }
        return instructionSteps
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

    var equipment: Equipment? {
        get { equipmentRaw.flatMap(Equipment.init(rawValue:)) }
        set { equipmentRaw = newValue?.rawValue }
    }

    /// Whether catalog media (bundled thumbnail + remote animation) exists.
    var hasMedia: Bool { gifFileName != nil }

    init(
        id: String,
        name: String,
        category: ExerciseCategory,
        primaryMuscles: [Muscle],
        secondaryMuscles: [Muscle] = [],
        isCustom: Bool = false,
        summary: String = "",
        instructionSteps: [String] = [],
        isUserModified: Bool = false,
        equipment: Equipment? = nil,
        gifFileName: String? = nil,
        nameTranslations: [String: String] = [:],
        summaryTranslations: [String: String] = [:],
        instructionTranslations: [String: [String]] = [:]
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
        self.equipmentRaw = equipment?.rawValue
        self.gifFileName = gifFileName
        self.nameTranslations = nameTranslations
        self.summaryTranslations = summaryTranslations
        self.instructionTranslations = instructionTranslations
    }
}
