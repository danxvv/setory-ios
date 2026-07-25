//
//  ProgressTabView.swift
//  gymapp
//
//  The Progress tab: workouts-per-week overview, muscle balance for the
//  current week or month, and the list of performed exercises leading to
//  the per-exercise progression charts.
//

import SwiftUI
import SwiftData
import Charts

/// Navigation payload that pushes an exercise's progression screen —
/// distinct from the plain-String value that pushes the detail screen.
struct ProgressionDestination: Hashable {
    let exerciseId: String
}

struct ProgressTabView: View {
    @Query private var sessions: [WorkoutSession]
    @Query private var allSeries: [WorkoutSeries]
    @Query private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var balancePeriod: ProgressStatsProvider.StatsPeriod = .week

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView {
                        Label("No progress yet", systemImage: "chart.xyaxis.line")
                    } description: {
                        Text("Finish a workout day and your progress will appear here.")
                    }
                    .accessibilityIdentifier("progress-empty")
                } else {
                    statsList
                }
            }
            .navigationTitle("Progress")
            .navigationDestination(for: ProgressionDestination.self) { destination in
                ExerciseProgressionView(exerciseId: destination.exerciseId)
            }
        }
    }

    private var statsList: some View {
        List {
            // While searching, collapse to just the exercise list.
            if searchText.isEmpty {
                overviewSection
                muscleBalanceSection
            }
            progressionListSection
        }
        .searchable(text: $searchText, prompt: Text("Search exercises"))
    }

    // MARK: - Training overview

    private var weekBuckets: [ProgressStatsProvider.WeekBucket] {
        ProgressStatsProvider.weeklySessionCounts(sessions: sessions)
    }

    private var headline: ProgressStatsProvider.HeadlineCounts {
        ProgressStatsProvider.headlineCounts(sessions: sessions)
    }

    private var overviewSection: some View {
        Section("Overview") {
            Chart(weekBuckets) { bucket in
                BarMark(
                    x: .value("Week", bucket.weekStart, unit: .weekOfYear),
                    y: .value("Workouts", bucket.sessionCount)
                )
                .foregroundStyle(.tint)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) {
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(), centered: true)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) {
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .frame(height: 160)
            .padding(.vertical, 4)
            .accessibilityIdentifier("overview-chart")

            LabeledContent("This week") {
                Text(headlineSummary(sessions: headline.weekSessions, series: headline.weekSeries))
            }
            .accessibilityIdentifier("headline-week")
            LabeledContent("This month") {
                Text(headlineSummary(sessions: headline.monthSessions, series: headline.monthSeries))
            }
            .accessibilityIdentifier("headline-month")
        }
    }

    private func headlineSummary(sessions: Int, series: Int) -> String {
        "\(String(localized: "\(sessions) workouts")) · \(String(localized: "\(series) series"))"
    }

    // MARK: - Muscle balance

    private var muscleCounts: [ProgressStatsProvider.MuscleCount] {
        ProgressStatsProvider.muscleBalance(series: allSeries, period: balancePeriod)
    }

    private var muscleBalanceSection: some View {
        Section("Muscle balance") {
            Picker("Period", selection: $balancePeriod) {
                Text("Week").tag(ProgressStatsProvider.StatsPeriod.week)
                Text("Month").tag(ProgressStatsProvider.StatsPeriod.month)
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("balance-period-picker")

            if muscleCounts.isEmpty {
                Text("No series in this period.")
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("balance-empty")
            } else {
                let maxCount = muscleCounts.first?.seriesCount ?? 1
                ForEach(muscleCounts) { item in
                    muscleRow(for: item, maxCount: maxCount)
                }
            }
        }
    }

    private func muscleRow(for item: ProgressStatsProvider.MuscleCount, maxCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(item.muscle.displayName)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text(String(localized: "\(item.seriesCount) series"))
                    .font(.subheadline)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: Double(item.seriesCount), total: Double(max(maxCount, 1)))
                .tint(.accentColor)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("balance-\(item.muscle.rawValue)")
    }

    // MARK: - Exercise progression list

    private var performedExercises: [Exercise] {
        let performedIds = Set(allSeries.compactMap { $0.exercise?.id })
        return exercises
            .filter { performedIds.contains($0.id) }
            .sorted { $0.localizedName.localizedStandardCompare($1.localizedName) == .orderedAscending }
    }

    /// Case- and diacritic-insensitive match on the localized or canonical
    /// English name (see Exercise.matchesSearch) — the same predicate the
    /// library and pickers use.
    private var filteredExercises: [Exercise] {
        guard !searchText.isEmpty else { return performedExercises }
        return performedExercises.filter { $0.matchesSearch(searchText) }
    }

    private var progressionListSection: some View {
        Section("Exercise progression") {
            if filteredExercises.isEmpty {
                Text("No exercises found")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(filteredExercises) { exercise in
                    NavigationLink(value: ProgressionDestination(exerciseId: exercise.id)) {
                        Label(
                            exercise.localizedName,
                            systemImage: exercise.category == .cardio ? "heart.circle" : "dumbbell"
                        )
                    }
                    .accessibilityIdentifier("progression-row-\(exercise.id)")
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Exercise.self, WorkoutSession.self, WorkoutSeries.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    _ = try? CatalogSeeder.seed(context: container.mainContext)
    return ProgressTabView()
        .modelContainer(container)
}
