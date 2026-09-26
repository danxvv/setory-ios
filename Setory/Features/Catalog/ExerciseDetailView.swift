//
//  ExerciseDetailView.swift
//  Setory
//
//  Detail screen for one catalog exercise: category, muscle targets,
//  description, instructions, the user's history for it, and related
//  exercises. The toolbar Edit button swaps the screen for the edit form.
//

import SwiftUI
import SwiftData

struct ExerciseDetailView: View {
    let exerciseId: String

    @Query private var exercises: [Exercise]
    @Query private var allSeries: [WorkoutSeries]
    @State private var isEditing = false

    private var exercise: Exercise? {
        exercises.first { $0.id == exerciseId }
    }

    /// Other exercises sharing a primary muscle, alphabetical, capped at 6.
    private var relatedExercises: [Exercise] {
        guard let exercise else { return [] }
        let primaries = Set(exercise.primaryMuscles)
        return exercises
            .filter { $0.id != exercise.id && !primaries.isDisjoint(with: $0.primaryMuscles) }
            .sorted(by: Exercise.byLocalizedName)
            .prefix(6)
            .map { $0 }
    }

    var body: some View {
        if let exercise {
            if isEditing {
                ExerciseEditForm(exercise: exercise) {
                    isEditing = false
                }
            } else {
                detailList(for: exercise)
            }
        } else {
            ContentUnavailableView("No exercises found", systemImage: "magnifyingglass")
        }
    }

    // MARK: - Read-only detail

    private func detailList(for exercise: Exercise) -> some View {
        List {
            if exercise.hasMedia {
                // No identifier on the Section: section modifiers cascade to
                // every row and would mask the media view's inner ids.
                Section {
                    ExerciseMediaView(exercise: exercise)
                        .listRowBackground(Color.clear)
                }
            }

            musclesSection(for: exercise)

            if !exercise.localizedSummary.isEmpty {
                Section("Description") {
                    Text(exercise.localizedSummary)
                        .lineSpacing(5)
                        .padding(.vertical, 6)
                        .accessibilityIdentifier("exercise-summary")
                }
            }

            let steps = exercise.localizedInstructionSteps
            if !steps.isEmpty {
                Section("Instructions") {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        instructionRow(index: index, step: step)
                    }
                }
            }

            historySection(for: exercise)

            if !relatedExercises.isEmpty {
                Section("Related exercises") {
                    ForEach(relatedExercises) { related in
                        NavigationLink(value: ExerciseRoute.detail(related.id)) {
                            Label(
                                related.localizedName,
                                systemImage: related.category == .cardio ? "heart.circle" : "dumbbell"
                            )
                        }
                        .accessibilityIdentifier("related-\(related.id)")
                    }
                }
            }
        }
        .setoryListStyle()
        .navigationTitle(exercise.localizedName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    isEditing = true
                }
                .accessibilityIdentifier("edit-exercise-button")
            }
        }
    }

    private func musclesSection(for exercise: Exercise) -> some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: exercise.category == .cardio ? "heart.circle" : "dumbbell")
                    .foregroundStyle(.tint)
                Text(exercise.category == .cardio ? "Cardio" : "Strength")
                    .font(.body.weight(.medium))
            }
            if let equipment = exercise.equipment {
                LabeledContent("Equipment") {
                    Text(equipment.displayName)
                }
                .accessibilityIdentifier("exercise-equipment")
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("Primary muscles")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                MuscleChips(muscles: exercise.primaryMuscles, emphasis: .primary)
                if !exercise.secondaryMuscles.isEmpty {
                    Text("Secondary muscles")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                    MuscleChips(muscles: exercise.secondaryMuscles, emphasis: .secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func instructionRow(index: Int, step: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            NumberBadge(index: index)
            Text(step)
                .lineSpacing(5)
        }
        .padding(.vertical, 8)
    }

    // MARK: - History

    @ViewBuilder
    private func historySection(for exercise: Exercise) -> some View {
        Section("History") {
            if let summary = ExerciseHistoryProvider.summary(for: exercise, in: allSeries) {
                LabeledContent("Last performed") {
                    Text(summary.lastPerformed.formatted(date: .abbreviated, time: .omitted))
                }
                LabeledContent("Best set") {
                    Text(summary.bestSet.valueSummary)
                }
                .accessibilityIdentifier("history-best-set")
                ForEach(summary.recentSessions) { session in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.subheadline.weight(.medium))
                        Text(session.series.map(\.valueSummary).joined(separator: " · "))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                NavigationLink(value: ExerciseRoute.progression(exercise.id)) {
                    Label("View progression", systemImage: "chart.xyaxis.line")
                }
                .accessibilityIdentifier("exercise-progression-link")
            } else {
                Text("Not performed yet")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("history-empty")
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Exercise.self, WorkoutSession.self, WorkoutSeries.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    _ = try? CatalogSeeder.seed(context: container.mainContext)
    return NavigationStack {
        ExerciseDetailView(exerciseId: "gv0025")
    }
    .modelContainer(container)
}
