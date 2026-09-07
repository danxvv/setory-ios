//
//  TemplateEditForm.swift
//  gymapp
//
//  One editor sheet for every template flow: create, edit, and
//  save-from-session (a pre-filled draft). Edits accumulate in a value-type
//  TemplateDraft, so cancel discards everything and nothing is persisted
//  until Save. The name field auto-fills with the suggested name only while
//  the user hasn't typed their own.
//

import SwiftUI
import SwiftData

struct TemplateEditForm: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// Nil when creating a new template (blank or pre-filled from a session).
    private let template: RoutineTemplate?
    /// AI suggestion rationale, shown above the form; nil everywhere else.
    private let rationale: String?

    @State private var draft: TemplateDraft
    /// The last suggestion auto-inserted into the name field. The field is
    /// only auto-updated while it still contains exactly that suggestion
    /// (or nothing), so a user-typed name is never overwritten.
    @State private var autoFilledName: String?
    @State private var showExercisePicker = false
    @State private var showPhotoMatch = false

    /// Edit flow: pre-filled from the stored template; the name is user
    /// content, never auto-replaced.
    init(template: RoutineTemplate) {
        self.template = template
        self.rationale = nil
        _draft = State(initialValue: TemplateDraft(template: template))
        _autoFilledName = State(initialValue: nil)
    }

    /// Create flow: blank by default, or pre-filled from a saved session
    /// or an AI suggestion (which also passes its rationale for display).
    /// An empty name is seeded with the suggestion when one exists.
    init(prefill: TemplateDraft = TemplateDraft(), rationale: String? = nil) {
        self.template = nil
        self.rationale = rationale
        var draft = prefill
        var autoFilled: String?
        if draft.trimmedName.isEmpty, let suggestion = draft.suggestedName {
            draft.name = suggestion
            autoFilled = suggestion
        }
        _draft = State(initialValue: draft)
        _autoFilledName = State(initialValue: autoFilled)
    }

    var body: some View {
        NavigationStack {
            Form {
                rationaleSection
                nameSection
                exercisesSection
                coverageSection
            }
            .gymListStyle()
            .navigationTitle(template == nil ? Text("New Template") : Text("Edit Template"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                    .accessibilityIdentifier("cancel-template-button")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(!draft.isSavable)
                    .accessibilityIdentifier("save-template-button")
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                ExerciseMultiPicker { selected in
                    draft.items.append(contentsOf: selected.map { TemplateDraft.Item(exercise: $0) })
                }
            }
            .sheet(isPresented: $showPhotoMatch) {
                PhotoMatchSheet { selected in
                    draft.items.append(contentsOf: selected.map { TemplateDraft.Item(exercise: $0) })
                }
            }
            .onChange(of: draft.items.map(\.exercise?.id)) {
                refreshSuggestedName()
            }
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var rationaleSection: some View {
        if let rationale {
            Section("Why this routine") {
                Text(rationale)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("suggestion-rationale")
            }
        }
    }

    private var nameSection: some View {
        Section {
            TextField("Name", text: $draft.name)
                .font(.title3.weight(.semibold))
                .padding(.vertical, 6)
                .accessibilityIdentifier("template-name-field")
        } footer: {
            if draft.trimmedName.isEmpty {
                Text("Name is required.")
                    .foregroundStyle(.red)
            }
        }
    }

    private var exercisesSection: some View {
        Section {
            ForEach($draft.items) { $item in
                itemRow($item)
            }
            .onDelete { draft.items.remove(atOffsets: $0) }
            .onMove { draft.items.move(fromOffsets: $0, toOffset: $1) }

            Button {
                showExercisePicker = true
            } label: {
                Label("Add Exercises", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(GymPrimaryButtonStyle())
            .accessibilityIdentifier("add-exercises-button")

            Button {
                showPhotoMatch = true
            } label: {
                Label("Match from Photo", systemImage: "camera.viewfinder")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .accessibilityIdentifier("photo-match-button")
        } header: {
            HStack {
                Text("Exercises")
                Spacer()
                if !draft.items.isEmpty {
                    EditButton()
                        .font(.caption)
                }
            }
        } footer: {
            if draft.items.isEmpty {
                Text("Add at least one exercise.")
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var coverageSection: some View {
        let primary = RoutineTemplate.primaryMusclesCovered(by: draft.exercises)
        let secondary = RoutineTemplate.secondaryMusclesCovered(by: draft.exercises)
        if !primary.isEmpty || !secondary.isEmpty {
            Section("Muscles worked") {
                if !primary.isEmpty {
                    MuscleChips(muscles: primary, emphasis: .primary)
                }
                if !secondary.isEmpty {
                    MuscleChips(muscles: secondary, emphasis: .secondary)
                }
            }
        }
    }

    private func itemRow(_ item: Binding<TemplateDraft.Item>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.wrappedValue.exercise?.localizedName ?? String(localized: "Exercise"))
                .font(.body.weight(.medium))
            Stepper(value: item.targetSets, in: RoutineTemplateItem.targetSetsRange) {
                Text("\(item.wrappedValue.targetSets) sets")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Suggested name

    private func refreshSuggestedName() {
        let isAutoFilled = draft.name.isEmpty || draft.name == autoFilledName
        guard isAutoFilled else { return }
        let suggestion = draft.suggestedName
        draft.name = suggestion ?? ""
        autoFilledName = suggestion
    }

    // MARK: - Save

    private func save() {
        guard draft.isSavable else { return }
        persisting("save routine template") {
            try TemplateStore(context: modelContext).save(draft, to: template)
            dismiss()
        }
    }
}

#Preview("Create") {
    let container = try! ModelContainer(
        for: Exercise.self, WorkoutSession.self, WorkoutSeries.self, RoutineTemplate.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    _ = try? CatalogSeeder.seed(context: container.mainContext)
    return TemplateEditForm()
        .modelContainer(container)
}
