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
    /// Description translations keyed by language code ("es"). English stays
    /// canonical in `summary`.
    var summaryTranslations: [String: String] = [:]
    /// Instruction-step translations keyed by language code ("es").
    var instructionTranslations: [String: [String]] = [:]

    /// Language whose content translations should render: the device
    /// language, falling back to canonical English for unsupported ones.
    static var contentLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    /// Display name. Catalog names are English-only by design (the dataset
    /// ships no translated names), so this is always the stored name; the
    /// accessor stays because call sites predate the catalog replacement.
    var localizedName: String { name }

    /// Description in the current device language, falling back to the
    /// canonical English summary. User-modified exercises show their stored
    /// text verbatim.
    var localizedSummary: String {
        localizedSummary(languageCode: Self.contentLanguageCode)
    }

    func localizedSummary(languageCode: String) -> String {
        guard !isUserModified else { return summary }
        return summaryTranslations[languageCode] ?? summary
    }

    /// Instruction steps in the current device language, falling back to the
    /// canonical English steps. User-modified exercises show their stored
    /// steps verbatim.
    var localizedInstructionSteps: [String] {
        localizedInstructionSteps(languageCode: Self.contentLanguageCode)
    }

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
        self.summaryTranslations = summaryTranslations
        self.instructionTranslations = instructionTranslations
    }
}
