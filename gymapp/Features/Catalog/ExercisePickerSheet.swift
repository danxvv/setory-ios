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
            HStack(spacing: 12) {
                ExerciseThumbnailView(exercise: exercise)
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.localizedName)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    MuscleChips(muscles: exercise.primaryMuscles, emphasis: .primary)
                }
            }
            .contentShape(Rectangle())
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
