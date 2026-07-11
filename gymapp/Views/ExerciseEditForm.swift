//
//  ExerciseEditForm.swift
//  gymapp
//
//  In-place edit mode for an exercise. Pre-filled with the values the user
//  was looking at (localized/resolved), so what you see is what you edit.
//  Saving persists every field and marks the exercise user-modified, which
//  freezes its text to the stored values (see Exercise.isUserModified).
//

import SwiftUI
import SwiftData

struct ExerciseEditForm: View {
    /// One editable instruction step with a stable identity for ForEach,
    /// so rows keep focus while text changes and reorder cleanly.
    private struct EditableStep: Identifiable, Equatable {
        let id = UUID()
        var text: String
    }

    @Environment(\.modelContext) private var modelContext

    let exercise: Exercise
    let onDone: () -> Void

    @State private var name: String
    @State private var category: ExerciseCategory
    @State private var primarySelection: Set<Muscle>
    @State private var secondarySelection: Set<Muscle>
    @State private var summary: String
    @State private var steps: [EditableStep]

    init(exercise: Exercise, onDone: @escaping () -> Void) {
        self.exercise = exercise
        self.onDone = onDone
        _name = State(initialValue: exercise.localizedName)
        _category = State(initialValue: exercise.category)
        _primarySelection = State(initialValue: Set(exercise.primaryMuscles))
        _secondarySelection = State(initialValue: Set(exercise.secondaryMuscles))
        _summary = State(initialValue: exercise.localizedSummary)
        _steps = State(initialValue: exercise.localizedInstructionSteps.map { EditableStep(text: $0) })
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isValid: Bool {
        !trimmedName.isEmpty && !primarySelection.isEmpty
    }

    var body: some View {
        Form {
            Section {
                TextField("Name", text: $name)
                    .accessibilityIdentifier("exercise-name-field")
                Picker("Category", selection: $category) {
                    Text("Strength").tag(ExerciseCategory.strength)
                    Text("Cardio").tag(ExerciseCategory.cardio)
                }
            } footer: {
                if trimmedName.isEmpty {
                    Text("Name is required.")
                        .foregroundStyle(.red)
                }
            }

            muscleSection(
                title: "Primary muscles",
                selection: $primarySelection,
                idPrefix: "primary"
            )
            .accessibilityIdentifier("primary-muscles-section")

            muscleSection(
                title: "Secondary muscles",
                selection: $secondarySelection,
                idPrefix: "secondary"
            )

            Section("Description") {
                TextEditor(text: $summary)
                    .frame(minHeight: 80)
                    .accessibilityIdentifier("exercise-summary-field")
            }

            Section {
                ForEach($steps) { $step in
                    TextField("Step", text: $step.text, axis: .vertical)
                }
                .onDelete { steps.remove(atOffsets: $0) }
                .onMove { steps.move(fromOffsets: $0, toOffset: $1) }
                Button {
                    steps.append(EditableStep(text: ""))
                } label: {
                    Label("Add step", systemImage: "plus.circle.fill")
                }
                .accessibilityIdentifier("add-step-button")
            } header: {
                HStack {
                    Text("Instructions")
                    Spacer()
                    EditButton()
                        .font(.caption)
                }
            }
        }
        .navigationTitle(exercise.localizedName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", role: .cancel) {
                    onDone()
                }
                .accessibilityIdentifier("cancel-edit-button")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    save()
                }
                .disabled(!isValid)
                .accessibilityIdentifier("save-exercise-button")
            }
        }
    }

    private func muscleSection(
        title: LocalizedStringKey,
        selection: Binding<Set<Muscle>>,
        idPrefix: String
    ) -> some View {
        Section {
            ForEach(Muscle.allCases, id: \.self) { muscle in
                Button {
                    if selection.wrappedValue.contains(muscle) {
                        selection.wrappedValue.remove(muscle)
                    } else {
                        selection.wrappedValue.insert(muscle)
                    }
                } label: {
                    HStack {
                        Text(muscle.displayName)
                            .foregroundStyle(.primary)
                        Spacer()
                        if selection.wrappedValue.contains(muscle) {
                            Image(systemName: "checkmark")
                                .foregroundStyle(.tint)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .accessibilityIdentifier("\(idPrefix)-muscle-\(muscle.rawValue)")
            }
        } header: {
            Text(title)
        } footer: {
            if idPrefix == "primary" && selection.wrappedValue.isEmpty {
                Text("Select at least one primary muscle.")
                    .foregroundStyle(.red)
            }
        }
    }

    private func save() {
        guard isValid else { return }
        let orderedPrimary = Muscle.allCases.filter(primarySelection.contains)
        let orderedSecondary = Muscle.allCases.filter { secondarySelection.contains($0) && !primarySelection.contains($0) }
        let cleanedSteps = steps
            .map { $0.text.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let cleanedSummary = summary.trimmingCharacters(in: .whitespacesAndNewlines)

        // A save with nothing actually changed stays a no-op so merely
        // visiting edit mode doesn't freeze the exercise's localization.
        let unchanged = trimmedName == exercise.localizedName
            && category == exercise.category
            && orderedPrimary == exercise.primaryMuscles
            && orderedSecondary == exercise.secondaryMuscles
            && cleanedSummary == exercise.localizedSummary
            && cleanedSteps == exercise.localizedInstructionSteps
        guard !unchanged else {
            onDone()
            return
        }

        exercise.name = trimmedName
        exercise.category = category
        exercise.primaryMuscles = orderedPrimary
        exercise.secondaryMuscles = orderedSecondary
        exercise.summary = cleanedSummary
        exercise.instructionSteps = cleanedSteps
        exercise.isUserModified = true
        do {
            try modelContext.save()
            onDone()
        } catch {
            modelContext.rollback()
            assertionFailure("Failed to save exercise edits: \(error)")
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Exercise.self, WorkoutSession.self, WorkoutSeries.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    _ = try? CatalogSeeder.seed(context: container.mainContext)
    let exercise = try! container.mainContext.fetch(FetchDescriptor<Exercise>()).first!
    return NavigationStack {
        ExerciseEditForm(exercise: exercise) {}
    }
    .modelContainer(container)
}
