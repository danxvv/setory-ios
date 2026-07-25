//
//  ContentView.swift
//  gymapp
//
//  The daily workout logging screen: calendar header, optional day plan
//  staged from a routine template, exercise picker, the day's series list,
//  and the "Finish Day" save action.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [WorkoutSession]
    @Query private var templates: [RoutineTemplate]
    @Query private var allSeries: [WorkoutSeries]

    @State private var selectedDate = Calendar.current.startOfDay(for: .now)
    /// Unsaved series per day (start-of-day keyed) so switching days
    /// doesn't discard in-progress drafts.
    @State private var drafts: [Date: [DraftSeries]] = [:]
    /// Staged template plan per day. View state only, like drafts: the plan
    /// is guidance and is never persisted.
    @State private var plans: [Date: DayPlan] = [:]
    @State private var exerciseToLog: Exercise?
    @State private var showExercisePicker = false
    /// Selection made inside the picker sheet; promoted to `exerciseToLog`
    /// once the picker has dismissed so the sheets never overlap.
    @State private var pendingLogExercise: Exercise?
    @State private var showTemplatePicker = false
    /// Template waiting for the user to confirm replacing the day's plan.
    @State private var templateAwaitingReplace: RoutineTemplate?
    /// Exercise whose animated demonstration is being viewed from a
    /// routine row's thumbnail.
    @State private var mediaExercise: Exercise?

    private var savedDays: Set<Date> {
        Set(sessions.map(\.date))
    }

    private var savedSession: WorkoutSession? {
        sessions.first { $0.date == selectedDate }
    }

    private var draftsForSelectedDay: [DraftSeries] {
        drafts[selectedDate] ?? []
    }

    private var planForSelectedDay: DayPlan? {
        plans[selectedDate]
    }

    /// User-entered names, so sort with locale-aware comparison in memory.
    private var sortedTemplates: [RoutineTemplate] {
        templates.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    MonthCalendarView(selectedDate: $selectedDate, savedDays: savedDays)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                planSection
                seriesSection
            }
            .listSectionSpacing(16)
            .navigationTitle("Workout Log")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                if savedSession == nil && !draftsForSelectedDay.isEmpty {
                    finishDayButton
                }
            }
            .sheet(item: $exerciseToLog) { exercise in
                SetEntrySheet(exercise: exercise) { draft in
                    drafts[selectedDate, default: []].append(draft)
                }
            }
            .sheet(isPresented: $showExercisePicker) {
                if let pending = pendingLogExercise {
                    pendingLogExercise = nil
                    exerciseToLog = pending
                }
            } content: {
                ExercisePickerSheet { exercise in
                    pendingLogExercise = exercise
                }
            }
            .sheet(isPresented: $showTemplatePicker) {
                TemplateApplyPicker(templates: sortedTemplates) { template in
                    requestApply(template)
                }
            }
            .sheet(item: $mediaExercise) { exercise in
                RoutineMediaSheet(exercise: exercise)
            }
            .confirmationDialog(
                "Replace current plan?",
                isPresented: Binding(
                    get: { templateAwaitingReplace != nil },
                    set: { if !$0 { templateAwaitingReplace = nil } }
                ),
                titleVisibility: .visible,
                presenting: templateAwaitingReplace
            ) { template in
                Button("Replace", role: .destructive) {
                    apply(template)
                }
            } message: { _ in
                Text("Your logged series will be kept.")
            }
        }
    }

    // MARK: - Day plan

    /// The staged template for the selected day, rendered as a checklist.
    /// Only unsaved days have plans; finishing or saving a day clears it.
    @ViewBuilder
    private var planSection: some View {
        if savedSession == nil, let plan = planForSelectedDay, !plan.exercises.isEmpty {
            Section {
                ForEach(plan.exercises) { planned in
                    plannedRow(planned)
                }
            } header: {
                Label {
                    Text("Plan: \(plan.templateName)")
                } icon: {
                    Image(systemName: "list.bullet.rectangle.portrait")
                }
            }
        }
    }

    private func plannedRow(_ planned: PlannedExercise) -> some View {
        let logged = DayPlan.loggedSets(for: planned.exercise, in: draftsForSelectedDay)
        let done = logged >= planned.targetSets
        // The thumbnail must be a sibling of the row's action button, not
        // inside its label: a borderless button nested in another button
        // never receives the tap.
        return HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? AnyShapeStyle(.green) : AnyShapeStyle(.quaternary))
            routineThumbnail(for: planned.exercise)
            Button {
                exerciseToLog = planned.exercise
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(planned.exercise.localizedName)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        if let reference = lastReference(for: planned.exercise) {
                            Text("Last: \(reference)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Text("\(logged)/\(planned.targetSets) sets")
                        .font(.subheadline)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
        }
        .padding(.vertical, 2)
    }

    /// The user's most recent recorded set for this exercise, formatted for
    /// the plan row's "Last: …" reference. Nil when never performed.
    private func lastReference(for exercise: Exercise) -> String? {
        guard let summary = ExerciseHistoryProvider.summary(for: exercise, in: allSeries),
              let lastSet = summary.recentSessions.first?.series.last
        else { return nil }
        return DraftSeries.summary(
            reps: lastSet.reps,
            weightKg: lastSet.weightKg,
            durationSeconds: lastSet.durationSeconds
        )
    }

    private func requestApply(_ template: RoutineTemplate) {
        if planForSelectedDay != nil {
            templateAwaitingReplace = template
        } else {
            apply(template)
        }
    }

    /// Stages the template's exercises as the day's plan. Replacing a plan
    /// never touches already-logged draft series.
    private func apply(_ template: RoutineTemplate) {
        withAnimation {
            plans[selectedDate] = DayPlan.staged(from: template)
        }
    }

    // MARK: - Series list

    @ViewBuilder
    private var seriesSection: some View {
        if let savedSession {
            Section {
                ForEach(savedSession.orderedSeries) { series in
                    seriesRow(
                        exercise: series.exercise,
                        name: series.exercise?.localizedName ?? String(localized: "Exercise"),
                        summary: DraftSeries.summary(
                            reps: series.reps,
                            weightKg: series.weightKg,
                            durationSeconds: series.durationSeconds
                        ),
                        index: series.order
                    )
                }

                NavigationLink {
                    RoutineDetailView(session: savedSession)
                } label: {
                    Label("View routine details", systemImage: "list.bullet.rectangle")
                        .font(.body.weight(.medium))
                }
            } header: {
                Label("Saved workout", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            } footer: {
                Text("This day is finished. Saved workouts can't be edited.")
            }
        } else {
            Section {
                if !templates.isEmpty {
                    startFromTemplateButton
                }
                addExerciseButton

                if draftsForSelectedDay.isEmpty {
                    ContentUnavailableView(
                        "No series yet",
                        systemImage: "figure.strengthtraining.traditional",
                        description: Text("Pick an exercise to log your first set of the day.")
                    )
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(Array(draftsForSelectedDay.enumerated()), id: \.element.id) { index, draft in
                        seriesRow(
                            exercise: draft.exercise,
                            name: draft.exercise.localizedName,
                            summary: draft.valueSummary,
                            index: index
                        )
                    }
                    .onDelete { offsets in
                        drafts[selectedDate, default: []].remove(atOffsets: offsets)
                    }
                }
            } header: {
                Text(selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide)))
            }
        }
    }

    private var startFromTemplateButton: some View {
        Button {
            showTemplatePicker = true
        } label: {
            Label("Start from template", systemImage: "list.bullet.rectangle.portrait.fill")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .accessibilityIdentifier("start-from-template-button")
    }

    private var addExerciseButton: some View {
        Button {
            showExercisePicker = true
        } label: {
            Label("Add Exercise", systemImage: "plus.circle.fill")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
        }
        .accessibilityIdentifier("add-exercise-button")
    }

    private func seriesRow(exercise: Exercise?, name: String, summary: String, index: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(index + 1)")
                .font(.footnote.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)
                .background(.quaternary, in: Circle())
            routineThumbnail(for: exercise)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body.weight(.medium))
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }

    /// Routine-row thumbnail: opens the media viewer when the exercise has
    /// media, stays inert (category-icon fallback) when it doesn't, and
    /// shows a neutral placeholder when the exercise is missing (deleted
    /// catalog entry). Borderless so the tap never triggers the row's
    /// primary action.
    @ViewBuilder
    private func routineThumbnail(for exercise: Exercise?) -> some View {
        if let exercise, exercise.hasMedia {
            Button {
                mediaExercise = exercise
            } label: {
                ExerciseThumbnailView(exercise: exercise)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(String(localized: "Show demonstration for \(exercise.localizedName)"))
            .accessibilityIdentifier("routine-thumbnail-\(exercise.id)")
        } else if let exercise {
            ExerciseThumbnailView(exercise: exercise)
        } else {
            Image(systemName: "questionmark")
                .foregroundStyle(.secondary)
                .frame(width: 40, height: 40)
                .background(.quaternary.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Finish Day

    private var finishDayButton: some View {
        Button {
            finishDay()
        } label: {
            Label("Finish Day", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(.bar)
    }

    private func finishDay() {
        let dayDrafts = draftsForSelectedDay
        guard !dayDrafts.isEmpty, savedSession == nil else { return }

        let session = WorkoutSession(date: selectedDate)
        modelContext.insert(session)
        for (index, draft) in dayDrafts.enumerated() {
            let series = WorkoutSeries(
                order: index,
                exercise: draft.exercise,
                reps: draft.reps,
                weightKg: draft.weightKg,
                durationSeconds: draft.durationSeconds
            )
            series.session = session
            modelContext.insert(series)
        }
        do {
            try modelContext.save()
            // Only logged drafts were persisted; the plan's unmet targets
            // are guidance and vanish with it.
            withAnimation {
                drafts[selectedDate] = nil
                plans[selectedDate] = nil
            }
        } catch {
            modelContext.rollback()
            assertionFailure("Failed to save workout session: \(error)")
        }
    }
}

/// Sheet listing the user's templates; tapping one applies it to the
/// selected day (after confirmation when a plan already exists).
private struct TemplateApplyPicker: View {
    let templates: [RoutineTemplate]
    let onSelect: (RoutineTemplate) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(templates) { template in
                Button {
                    onSelect(template)
                    dismiss()
                } label: {
                    row(for: template)
                }
                .foregroundStyle(.primary)
                .accessibilityIdentifier("apply-template-\(template.name)")
            }
            .navigationTitle("Start from template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func row(for template: RoutineTemplate) -> some View {
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
            if !primary.isEmpty {
                MuscleChips(muscles: primary, emphasis: .primary)
            }
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

#Preview {
    ContentView()
        .modelContainer(
            for: [Exercise.self, WorkoutSession.self, WorkoutSeries.self, RoutineTemplate.self, RoutineTemplateItem.self],
            inMemory: true
        )
}
