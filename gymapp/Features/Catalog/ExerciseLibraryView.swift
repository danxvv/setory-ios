//
//  ExerciseLibraryView.swift
//  gymapp
//
//  The Exercises tab: a searchable alphabetical list of the whole catalog,
//  entry point to the exercise detail screens.
//

import SwiftUI
import SwiftData

struct ExerciseLibraryView: View {
    @Query private var exercises: [Exercise]

    var body: some View {
        NavigationStack {
            FilteredExerciseList(exercises: exercises) { exercise in
                NavigationLink(value: ExerciseRoute.detail(exercise.id)) {
                    row(for: exercise)
                }
                .accessibilityIdentifier("exercise-row-\(exercise.id)")
            }
            .navigationTitle("Exercises")
            .exerciseDestinations()
        }
    }

    private func row(for exercise: Exercise) -> some View {
        HStack(spacing: 12) {
            ExerciseThumbnailView(exercise: exercise)
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.localizedName)
                    .font(.body.weight(.medium))
                MuscleChips(muscles: exercise.primaryMuscles, emphasis: .primary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Exercise.self, WorkoutSession.self, WorkoutSeries.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    _ = try? CatalogSeeder.seed(context: container.mainContext)
    return ExerciseLibraryView()
        .modelContainer(container)
}
