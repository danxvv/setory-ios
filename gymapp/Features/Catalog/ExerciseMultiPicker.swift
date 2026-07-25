//
//  ExerciseMultiPicker.swift
//  gymapp
//
//  Multi-select exercise picker sheet for the template editor. Reuses the
//  library's presentation: localized-name sort and case- and
//  diacritic-insensitive search.
//

import SwiftUI
import SwiftData

struct ExerciseMultiPicker: View {
    let onAdd: ([Exercise]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query private var exercises: [Exercise]

    @State private var searchText = ""
    @State private var filters = ExerciseFilters()
    @State private var selectedIds: Set<String> = []

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

    /// Selection in localized-name order, matching the list the user saw.
    private var selectedExercises: [Exercise] {
        sortedExercises.filter { selectedIds.contains($0.id) }
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
                        row(for: exercise)
                    }
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                ExerciseFilterBar(filters: $filters)
                    .background(.bar)
            }
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: Text("Search exercises"))
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
