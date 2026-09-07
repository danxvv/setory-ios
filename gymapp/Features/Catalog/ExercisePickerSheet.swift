//
//  ExercisePickerSheet.swift
//  gymapp
//
//  Single-select exercise picker for the logging screen.
//

import SwiftUI
import SwiftData

struct ExercisePickerSheet: View {
    let onSelect: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query private var exercises: [Exercise]

    var body: some View {
        NavigationStack {
            FilteredExerciseList(exercises: exercises) { exercise in
                row(for: exercise)
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func row(for exercise: Exercise) -> some View {
        Button {
            onSelect(exercise)
            dismiss()
        } label: {
            ExerciseRowContent(exercise: exercise)
        }
        .accessibilityIdentifier("picker-exercise-\(exercise.id)")
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Exercise.self, WorkoutSession.self, WorkoutSeries.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    _ = try? CatalogSeeder.seed(context: container.mainContext)
    return ExercisePickerSheet { _ in }
        .modelContainer(container)
}
