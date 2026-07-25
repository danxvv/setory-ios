//
//  RoutineDetailView.swift
//  gymapp
//
//  Read-only view of one saved workout session: a muscles-worked summary
//  and the session's series in recorded order. Reached from the Routines
//  list and from the logging screen's saved-workout section.
//

import SwiftUI
import SwiftData

struct RoutineDetailView: View {
    let session: WorkoutSession

    @State private var showSaveAsTemplate = false

    var body: some View {
        List {
            if !session.musclesWorked.isEmpty {
                Section("Muscles worked") {
                    Text(session.musclesWorked.map(\.displayName).joined(separator: " · "))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.tint)
                }
            }

            Section("Series") {
                ForEach(session.orderedSeries) { series in
                    seriesRow(series)
                }
            }
        }
        .navigationTitle(session.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Save as template", systemImage: "square.and.arrow.down.on.square") {
                    showSaveAsTemplate = true
                }
                .accessibilityIdentifier("save-as-template-button")
            }
        }
        // Pre-fills the standard editor from this session; nothing is
        // persisted unless the user saves there.
        .sheet(isPresented: $showSaveAsTemplate) {
            TemplateEditForm(prefill: TemplateDraft.draft(from: session))
        }
    }

    private func seriesRow(_ series: WorkoutSeries) -> some View {
        HStack(spacing: 12) {
            Text("\(series.order + 1)")
                .font(.footnote.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 26, height: 26)
                .background(.quaternary, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(series.exercise?.localizedName ?? String(localized: "Exercise"))
                    .font(.body.weight(.medium))
                Text(DraftSeries.summary(
                    reps: series.reps,
                    weightKg: series.weightKg,
                    durationSeconds: series.durationSeconds
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                if let muscles = series.exercise?.primaryMuscles, !muscles.isEmpty {
                    Text(muscles.map(\.displayName).joined(separator: " · "))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.tint)
                }
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Exercise.self, WorkoutSession.self, WorkoutSeries.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let bench = Exercise(
        id: "bench-press",
        name: "Bench Press",
        category: .strength,
        primaryMuscles: [.chest],
        secondaryMuscles: [.triceps, .shoulders]
    )
    container.mainContext.insert(bench)
    let session = WorkoutSession(date: .now)
    container.mainContext.insert(session)
    let series = WorkoutSeries(order: 0, exercise: bench, reps: 10, weightKg: 40)
    series.session = session
    container.mainContext.insert(series)

    return NavigationStack {
        RoutineDetailView(session: session)
    }
    .modelContainer(container)
}
