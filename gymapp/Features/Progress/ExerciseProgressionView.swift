//
//  ExerciseProgressionView.swift
//  gymapp
//
//  Progression charts for one exercise: max weight + session volume for
//  weighted strength work, max reps for bodyweight work, duration for
//  cardio. Sessions that set a new personal record carry a trophy marker.
//

import SwiftUI
import SwiftData
import Charts

struct ExerciseProgressionView: View {
    let exerciseId: String

    @Query private var exercises: [Exercise]
    @Query private var allSeries: [WorkoutSeries]

    private var exercise: Exercise? {
        exercises.first { $0.id == exerciseId }
    }

    private var progression: ProgressStatsProvider.Progression? {
        guard let exercise else { return nil }
        return ProgressStatsProvider.progression(for: exercise, in: allSeries)
    }

    var body: some View {
        if let exercise, let progression {
            List {
                bestSection(progression)
                metricSection(progression)
                if progression.metric == .weight {
                    volumeSection(progression)
                }
            }
            .navigationTitle(exercise.localizedName)
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView {
                Label("No progress yet", systemImage: "chart.xyaxis.line")
            } description: {
                Text("Finish a workout day and your progress will appear here.")
            }
        }
    }

    // MARK: - All-time best

    private func bestSection(_ progression: ProgressStatsProvider.Progression) -> some View {
        Section {
            LabeledContent("Best set") {
                Text(DraftSeries.summary(
                    reps: progression.bestSet.reps,
                    weightKg: progression.bestSet.weightKg,
                    durationSeconds: progression.bestSet.durationSeconds
                ))
            }
            .accessibilityIdentifier("progression-best")
        }
    }

    // MARK: - Metric chart

    private func metricSection(_ progression: ProgressStatsProvider.Progression) -> some View {
        Section {
            progressionChart(progression)
                .frame(height: 200)
                .padding(.vertical, 4)
                .accessibilityIdentifier("progression-chart")
        } header: {
            Text(metricTitle(progression.metric))
        } footer: {
            Text("Trophies mark personal-record sessions.")
        }
    }

    private func metricTitle(_ metric: ProgressStatsProvider.ProgressionMetric) -> LocalizedStringKey {
        switch metric {
        case .weight: "Max weight (kg)"
        case .reps: "Max reps"
        case .duration: "Duration (min)"
        }
    }

    /// Metric value in display units: kg, reps, or minutes.
    private func displayValue(_ point: ProgressStatsProvider.ProgressionPoint, metric: ProgressStatsProvider.ProgressionMetric) -> Double {
        metric == .duration ? point.value / 60 : point.value
    }

    /// Domain padded one day per side so single-session charts don't
    /// collapse: a lone bar would otherwise fill the whole plot and the
    /// axis would repeat the same date label.
    private func xDomain(for points: [ProgressStatsProvider.ProgressionPoint]) -> ClosedRange<Date> {
        let dates = points.map(\.date)
        let padding: TimeInterval = 86_400
        let lower = (dates.min() ?? .now) - padding
        let upper = (dates.max() ?? .now) + padding
        return lower...upper
    }

    /// Whole-day axis marks for short histories — automatic marks would
    /// subdivide below a day and repeat the same "d MMM" label; longer
    /// spans get automatic week/month granularity.
    private func xAxisValues(for points: [ProgressStatsProvider.ProgressionPoint]) -> AxisMarkValues {
        let domain = xDomain(for: points)
        let days = domain.upperBound.timeIntervalSince(domain.lowerBound) / 86_400
        return days <= 10 ? .stride(by: .day) : .automatic
    }

    private func progressionChart(_ progression: ProgressStatsProvider.Progression) -> some View {
        Chart(progression.points) { point in
            LineMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Value", displayValue(point, metric: progression.metric))
            )
            .foregroundStyle(.tint)
            PointMark(
                x: .value("Date", point.date, unit: .day),
                y: .value("Value", displayValue(point, metric: progression.metric))
            )
            .foregroundStyle(point.isPersonalRecord ? AnyShapeStyle(.orange) : AnyShapeStyle(.tint))
            .annotation(position: .top, spacing: 4) {
                if point.isPersonalRecord {
                    Image(systemName: "trophy.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .accessibilityLabel(Text("Personal record"))
                }
            }
        }
        .chartXScale(domain: xDomain(for: progression.points))
        .chartXAxis {
            AxisMarks(values: xAxisValues(for: progression.points)) {
                AxisGridLine()
                AxisValueLabel(format: .dateTime.day().month())
            }
        }
    }

    // MARK: - Volume chart (weighted strength only)

    private func volumeSection(_ progression: ProgressStatsProvider.Progression) -> some View {
        Section("Volume (kg)") {
            Chart(progression.points) { point in
                BarMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value("Volume (kg)", point.volume ?? 0)
                )
                .foregroundStyle(.tint)
            }
            .chartXScale(domain: xDomain(for: progression.points))
            .chartXAxis {
                AxisMarks(values: xAxisValues(for: progression.points)) {
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month())
                }
            }
            .frame(height: 140)
            .padding(.vertical, 4)
            .accessibilityIdentifier("progression-volume-chart")
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
        ExerciseProgressionView(exerciseId: "gv0025")
    }
    .modelContainer(container)
}
