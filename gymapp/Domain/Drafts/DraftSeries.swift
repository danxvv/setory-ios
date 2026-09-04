//
//  DraftSeries.swift
//  gymapp
//

import Foundation

/// An unsaved series accumulated on the logging screen. Lives in view state
/// only; it becomes a `WorkoutSeries` when the user taps "Finish Day".
struct DraftSeries: Identifiable, Equatable {
    let id = UUID()
    let exercise: Exercise
    var reps: Int?
    var weightKg: Double?
    var durationSeconds: Int?

    /// Human-readable values, e.g. "10 reps · 40 kg" or "15 min".
    var valueSummary: String {
        Self.summary(reps: reps, weightKg: weightKg, durationSeconds: durationSeconds)
    }

    static func summary(reps: Int?, weightKg: Double?, durationSeconds: Int?) -> String {
        if let durationSeconds {
            let minutes = durationSeconds / 60
            let seconds = durationSeconds % 60
            return seconds == 0
                ? String(localized: "\(minutes) min")
                : String(localized: "\(minutes) min \(seconds) s")
        }
        var parts: [String] = []
        if let reps {
            parts.append(String(localized: "\(reps) reps"))
        }
        if let weightKg {
            parts.append(String(localized: "\(weightKg.formatted(.number.precision(.fractionLength(0...2)))) kg"))
        }
        return parts.joined(separator: " · ")
    }
}

extension WorkoutSeries {
    /// Human-readable values, e.g. "10 reps · 40 kg" or "15 min".
    var valueSummary: String {
        DraftSeries.summary(reps: reps, weightKg: weightKg, durationSeconds: durationSeconds)
    }
}
