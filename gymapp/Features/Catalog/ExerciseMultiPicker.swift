//
//  ExerciseMultiPicker.swift
//  gymapp
//
//  Multi-select exercise picker sheet for the template editor.
//

import SwiftUI
import SwiftData

struct ExerciseMultiPicker: View {
    let onAdd: ([Exercise]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query private var exercises: [Exercise]

    @State private var selectedIds: Set<String> = []

    /// Selection in localized-name order, matching the list the user saw.
    private var selectedExercises: [Exercise] {
        exercises.filter { selectedIds.contains($0.id) }.sorted(by: Exercise.byLocalizedName)
    }

    var body: some View {
        NavigationStack {
            FilteredExerciseList(exercises: exercises) { exercise in
                row(for: exercise)
            }
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd(selectedExercises)
                        dismiss()
                    }
                    .disabled(selectedIds.isEmpty)
                    .accessibilityIdentifier("add-selected-exercises-button")
                }
            }
        }
    }

    private func row(for exercise: Exercise) -> some View {
        Button {
            if selectedIds.contains(exercise.id) {
                selectedIds.remove(exercise.id)
            } else {
                selectedIds.insert(exercise.id)
            }
        } label: {
            HStack(spacing: 12) {
                ExerciseThumbnailView(exercise: exercise, size: 36)
                Text(exercise.localizedName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer()
                if selectedIds.contains(exercise.id) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                }
            }
            .contentShape(Rectangle())
        }
        .accessibilityIdentifier("picker-exercise-\(exercise.id)")
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Exercise.self, WorkoutSession.self, WorkoutSeries.self, RoutineTemplate.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    _ = try? CatalogSeeder.seed(context: container.mainContext)
    return ExerciseMultiPicker { _ in }
        .modelContainer(container)
}
