# Add Saved Routines Screen

## Why

Saved workout sessions (routines) can currently only be seen by selecting their day on the logging screen's calendar, one day at a time. There is no place to browse the full history of saved routines, which is also the data the future AI suggestion feature builds on — users need a way to review what they have done.

## What Changes

- Add a new "Routines" screen that lists all saved workout sessions, newest first, with a summary per session (date, number of series, exercises involved).
- Add a routine detail view showing a session's ordered series with exercise names and recorded values (reps/weight or duration).
- Tapping a routine in the list opens its detail view.
- On the logging screen, tapping a calendar day that has a saved session navigates to that day's routine detail (in addition to the existing inline saved-series display for the selected day).
- Restructure the app root into a tab bar: "Log" (existing logging screen) and "Routines" (new screen).

## Capabilities

### New Capabilities

- `routine-history`: Browsing saved routines — the list screen of all saved sessions, the routine detail view for a single session, and empty-state behavior when nothing has been saved yet.

### Modified Capabilities

- `workout-logging`: Selecting a calendar day that already has a saved session additionally offers navigation to that day's routine detail view.

## Impact

- **New code**: `Views/RoutineListView.swift`, `Views/RoutineDetailView.swift`; a root `TabView` container.
- **Modified code**: `SetoryApp.swift` (root view becomes the tab container), `Views/ContentView.swift` and `Views/MonthCalendarView.swift` (navigation from a saved calendar day to the detail view).
- **Data**: read-only over existing SwiftData models (`WorkoutSession`, `WorkoutSeries`, `Exercise`); no schema changes, no migrations.
- **Dependencies/systems**: none — local-only feature, no backend involvement.
