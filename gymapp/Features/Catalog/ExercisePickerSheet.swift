//
//  ExercisePickerSheet.swift
//  gymapp
//
//  Single-select exercise picker for the logging screen: searchable,
//  filterable by muscle and equipment, thumbnail rows. Replaces the old
//  Menu dropdown, which was unusable at catalog scale.
//

import SwiftUI
import SwiftData

struct ExercisePickerSheet: View {
    let onSelect: (Exercise) -> Void

    @Environment(\.dismiss) private var dismiss
    @Query private var exercises: [Exercise]

    @State private var searchText = ""
    @State private var filters = ExerciseFilters()

    /// Sorted in memory with locale-aware comparison; display names are the
    /// stored names but ordering still follows the device locale's rules.
    private var filteredExercises: [Exercise] {
        filters.apply(to: exercises, searchText: searchText).sorted {
            $0.localizedName.localizedStandardCompare($1.localizedName) == .orderedAscending
        }
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
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: Text("Search exercises"))
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
