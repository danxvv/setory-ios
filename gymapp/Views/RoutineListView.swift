//
//  RoutineListView.swift
//  gymapp
//
//  The Routines tab: a Templates section (the user's reusable plans, with
//  create/edit/duplicate/delete) followed by the History section (saved
//  workout sessions, newest first, linking to RoutineDetailView).
//

import SwiftUI
import SwiftData

struct RoutineListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query private var templates: [RoutineTemplate]

    @State private var showNewTemplateEditor = false
    @State private var templateToEdit: RoutineTemplate?
    @State private var templateToDelete: RoutineTemplate?

    /// User-entered names, so sort with locale-aware comparison in memory.
    private var sortedTemplates: [RoutineTemplate] {
        templates.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        List {
            templatesSection
            historySection
        }
        .navigationTitle("Routines")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Template", systemImage: "plus") {
                    showNewTemplateEditor = true
                }
                .accessibilityIdentifier("create-template-button")
            }
        }
        .sheet(isPresented: $showNewTemplateEditor) {
            TemplateEditForm()
        }
        .sheet(item: $templateToEdit) { template in
            TemplateEditForm(template: template)
        }
        .confirmationDialog(
            "Delete this template?",
            isPresented: Binding(
                get: { templateToDelete != nil },
                set: { if !$0 { templateToDelete = nil } }
            ),
            titleVisibility: .visible,
            presenting: templateToDelete
        ) { template in
            Button("Delete", role: .destructive) {
                delete(template)
            }
        } message: { _ in
            Text("This won't affect saved workouts.")
        }
    }

    // MARK: - Templates

    private var templatesSection: some View {
        Section("Templates") {
            if sortedTemplates.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No templates yet")
                        .font(.body.weight(.medium))
                    Text("Create a template to plan your workouts.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            } else {
                ForEach(sortedTemplates) { template in
                    Button {
                        templateToEdit = template
                    } label: {
                        templateRow(template)
                    }
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("template-row-\(template.name)")
                    .contextMenu {
                        Button("Duplicate", systemImage: "plus.square.on.square") {
                            duplicate(template)
                        }
                        Button("Delete", systemImage: "trash", role: .destructive) {
                            templateToDelete = template
                        }
                    }
                }
                .onDelete { offsets in
                    templateToDelete = offsets.map { sortedTemplates[$0] }.first
                }
            }
        }
    }

    private func templateRow(_ template: RoutineTemplate) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(template.name)
                    .font(.body.weight(.medium))
                Spacer()
                Text("\(template.exercises.count) exercises")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            let primary = template.primaryMusclesCovered
            let secondary = template.secondaryMusclesCovered
            if !primary.isEmpty {
                MuscleChips(muscles: primary, emphasis: .primary)
            }
            if !secondary.isEmpty {
                MuscleChips(muscles: secondary, emphasis: .secondary)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }

    private func duplicate(_ template: RoutineTemplate) {
        let copy = RoutineTemplate(name: String(localized: "\(template.name) copy"))
        modelContext.insert(copy)
        for item in template.orderedItems {
            let copiedItem = RoutineTemplateItem(order: item.order, targetSets: item.targetSets, exercise: item.exercise)
            copiedItem.template = copy
            modelContext.insert(copiedItem)
        }
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            assertionFailure("Failed to duplicate template: \(error)")
        }
    }

    private func delete(_ template: RoutineTemplate) {
        modelContext.delete(template)
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            assertionFailure("Failed to delete template: \(error)")
        }
    }

    // MARK: - History

    private var historySection: some View {
        Section("History") {
            if sessions.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No routines yet")
                        .font(.body.weight(.medium))
                    Text("Days you finish on the Log tab will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            } else {
                ForEach(sessions) { session in
                    NavigationLink {
                        RoutineDetailView(session: session)
                    } label: {
                        row(for: session)
                    }
                }
            }
        }
    }

    private func row(for session: WorkoutSession) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(session.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year()))
                    .font(.body.weight(.medium))
                Spacer()
                Text("\(session.series.count) series")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !session.localizedExerciseNames.isEmpty {
                Text(session.localizedExerciseNames.joined(separator: ", "))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationStack {
        RoutineListView()
    }
    .modelContainer(
        for: [Exercise.self, WorkoutSession.self, WorkoutSeries.self, RoutineTemplate.self, RoutineTemplateItem.self],
        inMemory: true
    )
}
