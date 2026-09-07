//
//  LogView.swift
//  gymapp
//
//  The daily workout logging screen: calendar header, optional day plan
//  staged from a routine template, exercise picker, the day's series list,
//  and the "Finish Day" save action. The two list sections live in
//  DayPlanSection and DaySeriesSection; this file owns the day's state, the
//  sheets, and the save.
//

import SwiftUI
import SwiftData

struct LogView: View {
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

    /// Writable view of the selected day's drafts, so the series list can
    /// delete rows without knowing the day-keyed storage.
    private var draftsBinding: Binding<[DraftSeries]> {
        Binding(
            get: { drafts[selectedDate] ?? [] },
            set: { drafts[selectedDate] = $0 }
        )
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
                        // Keep seven date columns legible; the rest of the screen
                        // continues to use the user's full accessibility size.
                        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                if savedSession == nil, let plan = planForSelectedDay, !plan.exercises.isEmpty {
                    DayPlanSection(
                        plan: plan,
                        drafts: draftsForSelectedDay,
                        allSeries: allSeries,
                        onLog: { exerciseToLog = $0 },
                        onShowMedia: { mediaExercise = $0 }
                    )
                }

                DaySeriesSection(
                    savedSession: savedSession,
                    selectedDate: selectedDate,
                    drafts: draftsBinding,
                    hasTemplates: !templates.isEmpty,
                    onStartFromTemplate: { showTemplatePicker = true },
                    onAddExercise: { showExercisePicker = true },
                    onShowMedia: { mediaExercise = $0 }
                )
            }
            .gymListStyle()
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.large)
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
        .buttonStyle(GymPrimaryButtonStyle())
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .background(GymTheme.canvas)
    }

    private func finishDay() {
        let dayDrafts = draftsForSelectedDay
        guard !dayDrafts.isEmpty, savedSession == nil else { return }

        persisting("save workout session") {
            try WorkoutStore(context: modelContext).finishDay(
                date: selectedDate, drafts: dayDrafts
            )
            // Only logged drafts were persisted; the plan's unmet targets
            // are guidance and vanish with it.
            withAnimation {
                drafts[selectedDate] = nil
                plans[selectedDate] = nil
            }
        }
    }
}

#Preview {
    LogView()
        .modelContainer(
            for: [Exercise.self, WorkoutSession.self, WorkoutSeries.self, RoutineTemplate.self, RoutineTemplateItem.self],
            inMemory: true
        )
}
