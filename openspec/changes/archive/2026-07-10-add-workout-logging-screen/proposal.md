## Why

The app is still the untouched Xcode SwiftUI + SwiftData template — this change delivers the first and most essential screen: the daily workout logging screen. Without the ability to record exercises and save a day's session, none of the downstream features (routine history, AI suggestions) have data to work with.

## What Changes

- Replace the Xcode template scaffolding (`Item` model, placeholder `ContentView`) with the app's real domain models and first screen.
- Add a bundled exercise catalog (predefined exercises with category and primary/secondary muscle-target metadata) that powers the exercise selector.
- Add the workout logging screen:
  - A calendar at the top showing the current month, highlighting days that have saved workouts, and indicating the selected day (defaults to today).
  - A dropdown/picker to select an exercise from the catalog.
  - On selection, a popup to enter the set details: reps and weight for strength exercises, or duration for cardio/time-based exercises.
  - Each confirmed entry is appended as a "series" (set) to the day's list; the user can keep adding series of the same or other exercises.
  - A "Finish Day" button at the bottom that saves the accumulated series as that day's workout session (routine).
- Persist workout sessions locally with SwiftData so saved days survive app restarts and appear highlighted in the calendar.

## Capabilities

### New Capabilities
- `exercise-catalog`: Bundled library of exercises, each with name, category (strength vs. cardio/time-based), and required primary/secondary muscle-target metadata; exposed for selection in the UI.
- `workout-logging`: The daily logging screen — calendar, exercise selection, set-entry popup (reps/weight or time), the running list of series for the day, and saving the day via "Finish Day".

### Modified Capabilities

<!-- none — this is the first change; no existing specs -->

## Impact

- Existing `Setory` target: delete template `Item.swift`, rewrite `ContentView.swift` as the logging screen, register the new models in the shared `ModelContainer` in `SetoryApp.swift`.
- New SwiftData models: exercise, workout session, and series (set) entries.
- New unit-test target (the template project ships without one).
- New bundled resource: exercise catalog seed data (including muscle-target metadata required later by the AI suggestion contract).
- No network/API impact — this screen is fully offline; the AI suggestion endpoint is out of scope for this change.
