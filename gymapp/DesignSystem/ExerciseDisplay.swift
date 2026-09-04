//
//  ExerciseDisplay.swift
//  gymapp
//
//  The presentation boundary for per-locale exercise content. The entity
//  stores translations and resolves them for an explicit language code; this
//  file is the only place that asks what the device language currently is.
//
//  Keeping the ambient read out of the entity is what lets content resolution
//  be tested for a given language without pinning the test host's device
//  language — the entity accessors take the code, these conveniences supply it.
//

import Foundation

extension Exercise {
    /// Language whose content translations should render: the device
    /// language, falling back to canonical English for unsupported ones.
    static var contentLanguageCode: String {
        Locale.current.language.languageCode?.identifier ?? "en"
    }

    /// Display name in the current device language, falling back to the
    /// canonical English name. User-modified exercises show their stored
    /// name verbatim.
    var localizedName: String {
        localizedName(languageCode: Self.contentLanguageCode)
    }

    /// Description in the current device language, falling back to the
    /// canonical English summary.
    var localizedSummary: String {
        localizedSummary(languageCode: Self.contentLanguageCode)
    }

    /// Instruction steps in the current device language, falling back to the
    /// canonical English steps.
    var localizedInstructionSteps: [String] {
        localizedInstructionSteps(languageCode: Self.contentLanguageCode)
    }

    /// Case- and diacritic-insensitive search match. Both the resolved name
    /// and the canonical English one are tested: the dataset vocabulary is
    /// English, so a Spanish-device user searching "bench press" — off the
    /// machine's label, or out of an AI match result — must still find it.
    func matchesSearch(_ text: String) -> Bool {
        matchesSearch(text, languageCode: Self.contentLanguageCode)
    }

    /// List order: localized display name, locale-aware. SwiftData can't sort
    /// on a computed property, so lists sort in memory with this.
    static func byLocalizedName(_ lhs: Exercise, _ rhs: Exercise) -> Bool {
        lhs.localizedName.localizedStandardCompare(rhs.localizedName) == .orderedAscending
    }
}

extension WorkoutSession {
    /// Localized display names of the exercises involved, deduplicated,
    /// in series order. Series without an exercise are skipped.
    var localizedExerciseNames: [String] {
        var seen = Set<String>()
        var names: [String] = []
        for series in orderedSeries {
            if let name = series.exercise?.localizedName, seen.insert(name).inserted {
                names.append(name)
            }
        }
        return names
    }
}
