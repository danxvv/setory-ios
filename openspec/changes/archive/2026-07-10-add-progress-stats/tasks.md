# Tasks: Add Progress Charts & Stats

## 1. Stats aggregation provider

- [x] 1.1 Create `Services/ProgressStatsProvider.swift` with weekly session counts for the last 8 calendar weeks (calendar injected as a parameter, zero-filled weeks) and headline counts (sessions + total series for current week and month)
- [x] 1.2 Add muscle-balance aggregation: series count per primary muscle for a week/month period, sorted descending, zero-count muscles omitted
- [x] 1.3 Add per-exercise progression series: one data point per session in date order, metric chosen by category (max weight + session volume for weighted strength, omitting weightless sessions; max reps for never-weighted strength; longest duration for cardio) plus PR-session detection reusing `ExerciseHistoryProvider.bestSet` ordering and the all-time best
- [x] 1.4 Unit tests for 1.1–1.3 with a pinned `Calendar`: week bucketing across month boundaries, empty history, single session, mixed weighted/unweighted sets, cardio, PR sequence

## 2. Progress tab

- [x] 2.1 Create `Views/ProgressTabView.swift` with its own `NavigationStack`, add the fourth `Tab("Progress", systemImage: "chart.xyaxis.line")` to `RootTabView`, and show the localized whole-tab empty state when no sessions exist
- [x] 2.2 Training overview section: Swift Charts bar chart of workouts per week (8 weeks) plus headline week/month counts
- [x] 2.3 Muscle balance section: Week/Month segmented picker, per-muscle series counts with localized muscle names, localized empty state for an empty period
- [x] 2.4 Performed-exercise list section: only exercises with logged series, sorted by localized name, case-/diacritic-insensitive search, rows with name + category icon navigating to the progression screen

## 3. Exercise progression screen

- [x] 3.1 Create `Views/ExerciseProgressionView.swift` rendering the category-appropriate chart (weight+volume / reps / duration) with locale-aware axis formatting, correct from a single data point
- [x] 3.2 Add PR markers on improving sessions and the all-time best-set summary above the chart
- [x] 3.3 Add the conditional progression link to `ExerciseDetailView`'s history section (shown only when history exists)

## 4. Localization

- [x] 4.1 Add all new UI strings (tab label, section headers, period picker, empty states, PR/best labels, accessibility labels) to `Localizable.xcstrings` with Spanish translations; audit that no new key is missing `es`

## 5. Verification

- [x] 5.1 UI tests: Progress tab appears and shows the empty state on a fresh install; after logging a session the overview and muscle sections populate; navigation to the progression screen works from both the Progress list and the exercise detail screen
- [x] 5.2 Build and run the full unit + UI test suites; verify charts and Spanish rendering in the simulator
