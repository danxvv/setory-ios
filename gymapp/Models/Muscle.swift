//
//  Muscle.swift
//  gymapp
//

import Foundation

/// Major muscle groups targeted by exercises. Raw values are stable strings
/// that serialize directly into seed data and, later, the AI suggestion API.
enum Muscle: String, Codable, CaseIterable, Sendable {
    case chest
    case back
    case lats
    case traps
    case shoulders
    case biceps
    case triceps
    case forearms
    case abs
    case obliques
    case lowerBack = "lower_back"
    case glutes
    case quads
    case hamstrings
    case calves
    case fullBody = "full_body"

    var displayName: String {
        switch self {
        case .chest: String(localized: "Chest")
        case .back: String(localized: "Back")
        case .lats: String(localized: "Lats")
        case .traps: String(localized: "Traps")
        case .shoulders: String(localized: "Shoulders")
        case .biceps: String(localized: "Biceps")
        case .triceps: String(localized: "Triceps")
        case .forearms: String(localized: "Forearms")
        case .abs: String(localized: "Abs")
        case .obliques: String(localized: "Obliques")
        case .lowerBack: String(localized: "Lower Back")
        case .glutes: String(localized: "Glutes")
        case .quads: String(localized: "Quads")
        case .hamstrings: String(localized: "Hamstrings")
        case .calves: String(localized: "Calves")
        case .fullBody: String(localized: "Full Body")
        }
    }
}

/// How an exercise is measured: reps (+ optional weight) or elapsed time.
enum ExerciseCategory: String, Codable, CaseIterable, Sendable {
    case strength
    case cardio
}
