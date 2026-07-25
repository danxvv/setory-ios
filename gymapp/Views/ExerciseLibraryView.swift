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
    @State private var searchText = ""
    @State private var filters = ExerciseFilters()

    /// Sorted in memory by localized display name: SwiftData can't sort on
    /// a computed property, and Spanish alphabetization differs from English.
    private var sortedExercises: [Exercise] {
        exercises.sorted {
            $0.localizedName.localizedStandardCompare($1.localizedName) == .orderedAscending
        }
    }

    /// Search plus muscle/equipment filters over the sorted catalog.
    private var filteredExercises: [Exercise] {
        filters.apply(to: sortedExercises, searchText: searchText)
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredExercises.isEmpty {
                    ContentUnavailableView(
                        "No exercises found",
                        systemImage: "magnifyingglass",
                        description: Text("Try a different search.")
                    )
                } else {
                    List(filteredExercises) { exercise in
                        NavigationLink(value: exercise.id) {
                            row(for: exercise)
                        }
                        .accessibilityIdentifier("exercise-row-\(exercise.id)")
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                ExerciseFilterBar(filters: $filters)
                    .background(.bar)
            }
            .navigationTitle("Exercises")
            .navigationDestination(for: String.self) { exerciseId in
                ExerciseDetailView(exerciseId: exerciseId)
            }
            .navigationDestination(for: ProgressionDestination.self) { destination in
                ExerciseProgressionView(exerciseId: destination.exerciseId)
            }
            .searchable(text: $searchText, prompt: Text("Search exercises"))
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
