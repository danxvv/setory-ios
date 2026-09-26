# Tasks — Add Saved Routines Screen

## 1. App structure

- [x] 1.1 Create `RootTabView` with "Log" (existing `ContentView`) and "Routines" tabs, each in its own `NavigationStack`, and make it the root view in `SetoryApp`

## 2. Routine detail view

- [x] 2.1 Create `Views/RoutineDetailView.swift` taking a `WorkoutSession`: ordered series rows with exercise name and value summary (reuse `DraftSeries.summary`), placeholder name when the series has no exercise
- [x] 2.2 Add muscle-target presentation: primary-muscle indication per series row and a "muscles worked" summary for the session; omit muscle info for series without an exercise

## 3. Routines list screen

- [x] 3.1 Create `Views/RoutineListView.swift` with `@Query(sort: \WorkoutSession.date, order: .reverse)`: rows showing date, series count, and exercise names; `NavigationLink` to `RoutineDetailView`
- [x] 3.2 Add empty state (`ContentUnavailableView`) shown when no sessions are saved

## 4. Logging screen entry point

- [x] 4.1 In `ContentView`, make the "Saved workout" section link to `RoutineDetailView` for the selected day's session

## 5. Tests & verification

- [x] 5.1 Unit tests: session summary data (series count, exercise names, muscles-worked aggregation) including the missing-exercise fallback
- [x] 5.2 UI test: seed a saved session, open the Routines tab, assert the row appears and tapping it shows the detail; assert empty state with `-uitest-reset`
- [x] 5.3 UI test: from the Log tab, select a saved day and navigate to the detail via the saved-workout section
- [x] 5.4 Build and run full test suite; verify both entry points on the simulator
