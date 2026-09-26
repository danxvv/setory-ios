//
//  DayPlanSection.swift
//  Setory
//
//  The staged template for the selected day, rendered as a checklist inside
//  the logging screen's List. Only unsaved days have plans; finishing or
//  saving a day clears it.
//

import SwiftUI

struct DayPlanSection: View {
    let plan: DayPlan
    /// The day's unsaved series, which decide each row's logged/target count.
    let drafts: [DraftSeries]
    /// All saved series, for each row's "Last: …" reference.
    let allSeries: [WorkoutSeries]
    let onLog: (Exercise) -> Void
    let onShowMedia: (Exercise) -> Void

    var body: some View {
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

    private func plannedRow(_ planned: PlannedExercise) -> some View {
        let logged = DayPlan.loggedSets(for: planned.exercise, in: drafts)
        let done = logged >= planned.targetSets
        // The thumbnail must be a sibling of the row's action button, not
        // inside its label: a borderless button nested in another button
        // never receives the tap.
        return HStack(spacing: 12) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(done ? AnyShapeStyle(.green) : AnyShapeStyle(.quaternary))
            RoutineThumbnail(exercise: planned.exercise, onShowMedia: onShowMedia)
            Button {
                onLog(planned.exercise)
            } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
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
        .padding(.vertical, 8)
    }

    /// The user's most recent recorded set for this exercise, formatted for
    /// the plan row's "Last: …" reference. Nil when never performed.
    private func lastReference(for exercise: Exercise) -> String? {
        ExerciseHistoryProvider.summary(for: exercise, in: allSeries)?
            .recentSessions.first?.series.last?.valueSummary
    }
}
