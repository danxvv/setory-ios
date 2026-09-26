//
//  ExerciseRoute.swift
//  Setory
//
//  The exercise screens any tab can push, as one route type registered in one
//  place. Before this existed the detail screen was pushed as a bare String —
//  claiming every String value pushed in that stack — and the progression
//  screen was registered separately in two tabs.
//

import SwiftUI

enum ExerciseRoute: Hashable {
    /// The catalog detail screen for an exercise id.
    case detail(String)
    /// The per-exercise progression charts for an exercise id.
    case progression(String)
}

extension View {
    /// Registers both exercise destinations. Apply once per navigation stack
    /// that can reach them; the Exercises and Progress tabs both do.
    func exerciseDestinations() -> some View {
        navigationDestination(for: ExerciseRoute.self) { route in
            switch route {
            case .detail(let exerciseId):
                ExerciseDetailView(exerciseId: exerciseId)
            case .progression(let exerciseId):
                ExerciseProgressionView(exerciseId: exerciseId)
            }
        }
    }
}
