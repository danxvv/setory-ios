# Design: Add Progress Charts & Stats

## Context

Every logged set is already persisted in SwiftData (`WorkoutSession` → `WorkoutSeries` with reps/weight/duration and a relationship to `Exercise`, which carries muscle-target metadata). `ExerciseHistoryProvider` established the project's pattern for read-only history aggregation: pure static functions over already-fetched model arrays, unit-testable without UI. The app has three root tabs (Log, Exercises, Routines) and targets iOS 17+, so Swift Charts is fully available. This change is presentation-only — no model or persistence changes.

## Goals / Non-Goals

**Goals:**
- A fourth "Progress" root tab: workouts-per-week overview, per-muscle volume balance, and a list of performed exercises leading to progression charts.
- A per-exercise progression screen with PR markers, reachable from the Progress tab and from the exercise detail history section.
- All aggregation logic pure and unit-tested; all UI localized (EN/ES) with graceful empty states.

**Non-Goals:**
- Goals, streaks, or gamification (separate future change).
- Body-weight/measurement tracking, HealthKit export, CSV export, unit preference (weights stay kg).
- AI routine suggestions — the stats provider is app-local and does not touch the future REST contract.
- Editing data from charts; everything here is read-only.

## Decisions

### 1. Swift Charts for rendering
Use the system Charts framework (`import Charts`).
- *Alternative — hand-rolled SwiftUI shapes*: full control but reimplements axes, scaling, and accessibility for no benefit.
- *Alternative — third-party (DGCharts)*: adds the project's first external dependency for capabilities Swift Charts already has on iOS 17.
Swift Charts gives locale-aware axis formatting and built-in accessibility (audio graph, per-mark labels) for free, matching the localization spec's accessibility requirement.

### 2. Aggregation as a pure provider, in-memory
Add `ProgressStatsProvider` (enum with static functions, mirroring `ExerciseHistoryProvider`): weekly session counts, per-muscle series counts for a period, and per-exercise session time series. Views fetch with `@Query` and pass arrays in.
- *Alternative — SwiftData aggregate queries*: SwiftData has no aggregation API; `#Predicate` can filter but not group. At personal-gym scale (a few thousand series after years of use) in-memory grouping is well under a frame budget.
- Date bucketing uses `Calendar.current.dateInterval(of: .weekOfYear, ...)` so week boundaries follow the device locale (Monday vs Sunday starts). Tests inject a fixed calendar.

### 3. Muscle balance counts series against primary muscles only
Each series contributes 1 to each of its exercise's primary muscles; secondary muscles are excluded. This matches the existing `WorkoutSession.musclesWorked` semantics and keeps strength, bodyweight, and cardio series comparable (weight-based volume would zero out cardio and bodyweight work). Periods: a Week/Month segmented picker (current calendar week / current calendar month).
- *Alternative — reps×weight tonnage per muscle*: more precise for barbell work but meaningless for cardio and unweighted sets; can be added later as a second metric without spec changes to the counting requirement.

### 4. Per-exercise progression: one metric per category, session-granular
One data point per session (not per set) keeps charts readable:
- Strength with any weighted history: line of max weight per session, plus a bar overlay of session volume (Σ reps×weight over weighted sets).
- Strength never weighted (bodyweight): line of max reps per session.
- Cardio: line of duration per session (longest set per session).
PR markers annotate sessions where the running best (per `ExerciseHistoryProvider.bestSet` ordering) improved; the all-time best is summarized above the chart. Reusing `bestSet` semantics keeps "best" consistent with the detail screen.

### 5. Navigation and screen structure
`RootTabView` gains a `Tab("Progress", systemImage: "chart.xyaxis.line")` owning its own `NavigationStack`, consistent with the existing tabs. The progression screen takes an `Exercise` and is pushed from both the Progress tab's exercise list and `ExerciseDetailView`'s history section (link shown only when history exists). The Progress tab's exercise list shows only performed exercises — an unperformed exercise has no chart to show, and its detail screen is already reachable from the Exercises tab.

## Risks / Trade-offs

- [Fetching all series on tab open grows with history] → Single fetch + one O(n) pass; revisit with a date-bounded fetch only if profiling ever shows a problem. No premature fetch limits.
- [Locale-dependent week bucketing makes tests flaky] → Provider functions take a `Calendar` parameter; tests pin `Calendar(identifier: .gregorian)` with a fixed `firstWeekday` and time zone.
- [Charts with 1–2 data points look broken] → Explicit rule: any chart renders from 1 point (Swift Charts handles single-mark plots); sections show a localized empty state at 0 points rather than an empty chart.
- [Mixed weighted/unweighted history for one exercise] → Weight chart plots only sessions containing weighted sets; if none exist the exercise falls into the reps variant. Sessions with no weighted sets are omitted from the weight line rather than plotted as 0, avoiding misleading dips.
- [Muscle-count metric under-represents secondary work] → Accepted for v1; documented in the spec as primary-muscle counting so a future metric change is an explicit spec delta.

## Open Questions

None blocking — period picker granularity (week/month) and the 8-week overview window are chosen; both are trivial to tune later without structural change.
