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
    @State private var showAISettings = false
    @State private var showSuggestSheet = false
    /// Handed over by the suggest sheet right before it dismisses; moved
    /// into `suggestionToReview` once the sheet is gone so the editor can
    /// present without fighting the dismissal animation.
    @State private var pendingSuggestion: RoutineSuggestion?
    @State private var suggestionToReview: RoutineSuggestion?

    /// User-entered names, so sort with locale-aware comparison in memory.
    private var sortedTemplates: [RoutineTemplate] {
        templates.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        List {
            Section {
                GymIntro(
                    title: "Make room for your next workout",
                    subtitle: "Your plans and finished workouts, together.",
                    symbol: "square.stack.3d.up.fill"
                )
            }
            .listRowBackground(GymTheme.softAccent)
            templatesSection
            historySection
        }
        .gymListStyle()
        .navigationTitle("Routines")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Template", systemImage: "plus") {
                    showNewTemplateEditor = true
                }
                .accessibilityIdentifier("create-template-button")
            }
            ToolbarItem {
                Button("Suggest with AI", systemImage: "sparkles") {
                    showSuggestSheet = true
                }
                .accessibilityIdentifier("suggest-with-ai-button")
            }
            ToolbarItem {
                Button("AI Settings", systemImage: "gearshape") {
                    showAISettings = true
                }
                .accessibilityIdentifier("ai-settings-button")
            }
        }
        .sheet(isPresented: $showNewTemplateEditor) {
            TemplateEditForm()
        }
        .sheet(item: $templateToEdit) { template in
            TemplateEditForm(template: template)
        }
        .sheet(isPresented: $showAISettings) {
            AISettingsView()
        }
        .sheet(isPresented: $showSuggestSheet, onDismiss: presentPendingSuggestion) {
            SuggestRoutineSheet { suggestion in
                pendingSuggestion = suggestion
            }
        }
        .sheet(item: $suggestionToReview) { suggestion in
            TemplateEditForm(prefill: suggestion.draft, rationale: suggestion.rationale)
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

    /// Runs when the suggest sheet finishes dismissing: promotes the
    /// handed-over suggestion so the editor sheet presents next.
    private func presentPendingSuggestion() {
        guard let pending = pendingSuggestion else { return }
        pendingSuggestion = nil
        suggestionToReview = pending
    }

    // MARK: - Templates

    private var templatesSection: some View {
        Section("Templates") {
            if sortedTemplates.isEmpty {
                GymIntro(
                    title: "No templates yet",
                    subtitle: "Create a template to plan your workouts.",
                    symbol: "list.bullet.clipboard"
                )
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
        HStack(alignment: .top, spacing: 14) {
            GymIcon(symbol: "dumbbell.fill")
            VStack(alignment: .leading, spacing: 10) {
                Text(template.name)
                    .font(.headline)
                Text("\(template.exercises.count) exercises")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                let primary = template.primaryMusclesCovered
                let secondary = template.secondaryMusclesCovered
                if !primary.isEmpty {
                    MuscleChips(muscles: primary, emphasis: .primary)
                }
                if !secondary.isEmpty {
                    MuscleChips(muscles: secondary, emphasis: .secondary)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(.tertiary)
                .padding(.top, 16)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private func duplicate(_ template: RoutineTemplate) {
        persisting("duplicate template") {
            try TemplateStore(context: modelContext).duplicate(template)
        }
    }

    private func delete(_ template: RoutineTemplate) {
        persisting("delete template") {
            try TemplateStore(context: modelContext).delete(template)
        }
    }

    // MARK: - History

    private var historySection: some View {
        Section("History") {
            if sessions.isEmpty {
                GymIntro(
                    title: "No routines yet",
                    subtitle: "Days you finish on the Log tab will appear here.",
                    symbol: "clock.arrow.circlepath"
                )
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
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 2) {
                Text(session.date.formatted(.dateTime.day()))
                    .font(.title2.bold())
                Text(session.date.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.tint)
            .frame(minWidth: 52, minHeight: 60)
            .background(GymTheme.softAccent, in: RoundedRectangle(cornerRadius: 16))
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(session.date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).year()))
                    .font(.headline)
                Text("\(session.series.count) series")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.tint)
                if !session.localizedExerciseNames.isEmpty {
                    Text(session.localizedExerciseNames.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 8)
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
