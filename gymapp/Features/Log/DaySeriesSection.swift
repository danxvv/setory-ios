//
//  DaySeriesSection.swift
//  gymapp
//
//  The selected day's series inside the logging screen's List: either the
//  read-only saved workout (with its routine-detail link) or the editable
//  draft list with its add-exercise and start-from-template actions.
//

import SwiftUI

struct DaySeriesSection: View {
    /// Non-nil once the day is finished, which makes the section read-only.
    let savedSession: WorkoutSession?
    let selectedDate: Date
    /// The day's unsaved series; bound so rows can be swiped away.
    @Binding var drafts: [DraftSeries]
    /// Whether the user has any template to start from.
    let hasTemplates: Bool
    let onStartFromTemplate: () -> Void
    let onAddExercise: () -> Void
    let onShowMedia: (Exercise) -> Void

    var body: some View {
        if let savedSession {
            savedSection(savedSession)
        } else {
            draftSection
        }
    }

    // MARK: - Saved day

    private func savedSection(_ savedSession: WorkoutSession) -> some View {
        Section {
            ForEach(savedSession.orderedSeries) { series in
                SeriesRow(
                    exercise: series.exercise,
                    name: series.exercise?.localizedName ?? String(localized: "Exercise"),
                    summary: series.valueSummary,
                    index: series.order,
                    onShowMedia: onShowMedia
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
                .foregroundStyle(Color.accentColor)
        } footer: {
            Text("This day is finished. Saved workouts can't be edited.")
        }
    }

    // MARK: - Unsaved day

    private var draftSection: some View {
        Section {
            if hasTemplates {
                startFromTemplateButton
            }
            addExerciseButton

            if drafts.isEmpty {
                GymIntro(
                    title: "No series yet",
                    subtitle: "Pick an exercise to log your first set of the day.",
                    symbol: "figure.strengthtraining.traditional"
                )
                .listRowSeparator(.hidden)
            } else {
                ForEach(Array(drafts.enumerated()), id: \.element.id) { index, draft in
                    SeriesRow(
                        exercise: draft.exercise,
                        name: draft.exercise.localizedName,
                        summary: draft.valueSummary,
                        index: index,
                        onShowMedia: onShowMedia
                    )
                }
                .onDelete { offsets in
                    drafts.remove(atOffsets: offsets)
                }
            }
        } header: {
            Text(selectedDate.formatted(.dateTime.weekday(.wide).day().month(.wide)))
        }
    }

    private var startFromTemplateButton: some View {
        Button {
            onStartFromTemplate()
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
            onAddExercise()
        } label: {
            Label("Add Exercise", systemImage: "plus.circle.fill")
                .font(.body.weight(.semibold))
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(GymPrimaryButtonStyle())
        .listRowSeparator(.hidden)
        .accessibilityIdentifier("add-exercise-button")
    }
}
