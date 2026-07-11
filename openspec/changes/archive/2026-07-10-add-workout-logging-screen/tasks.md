## 1. Project Restructuring

- [x] 1.1 Restructure the existing `gymapp` target: add folder groups `Models/`, `Views/`, `Services/`, `Resources/`; delete the template `Item.swift` and strip the boilerplate list UI from `ContentView.swift`
- [x] 1.2 Add a unit-test target to the project (the template ships without one) and verify it runs
- [x] 1.3 Update the `ModelContainer` schema in `gymappApp.swift` to register the new models (as they land in group 2) and verify the app builds and runs on the simulator

## 2. Data Models

- [x] 2.1 Define the `Muscle` enum (major muscle groups) and `ExerciseCategory` enum (`strength`, `cardio`)
- [x] 2.2 Create the `Exercise` SwiftData model (stable id, name, category, primaryMuscles, secondaryMuscles, isCustom)
- [x] 2.3 Create the `WorkoutSession` (start-of-day date, finishedAt, ordered series relationship) and `WorkoutSeries` (order, exercise ref, reps?, weightKg?, durationSeconds?) models
- [x] 2.4 Add unit tests covering model creation and the one-session-per-day date normalization

## 3. Exercise Catalog

- [x] 3.1 Author `exercises.json` seed data: ~30 strength exercises and ~5 cardio exercises, each with primary/secondary muscles
- [x] 3.2 Implement `CatalogSeeder` service: load the JSON on launch and insert missing exercises idempotently (keyed by stable id)
- [x] 3.3 Add unit tests for seeding: first launch seeds all, second launch inserts no duplicates, alphabetical fetch for the selection UI

## 4. Calendar Header

- [x] 4.1 Build the month-grid calendar view: current month layout, month navigation, day selection defaulting to today
- [x] 4.2 Decorate days: saved-workout marker driven by persisted sessions, selected-day ring, today indicator
- [x] 4.3 Add unit tests for the calendar date math (month boundaries, first weekday, start-of-day normalization)

## 5. Logging Screen

- [x] 5.1 Create the logging screen scaffold: calendar on top, exercise dropdown (alphabetical catalog), empty-state series list, screen state for the selected day's draft series
- [x] 5.2 Implement the set-entry sheet: exercise-name title, reps + optional weight inputs for strength, duration input for cardio, validation-gated Confirm and Cancel
- [x] 5.3 Wire confirmed entries into the day's series list: ordered rows showing exercise name and values, swipe-to-delete for unsaved series
- [x] 5.4 Implement "Finish Day": button visible only with unsaved series, saves the session and its series in one transaction, calendar highlight updates
- [x] 5.5 Show saved days read-only: selecting a highlighted day lists its persisted series without the "Finish Day" button
- [x] 5.6 Visual polish pass: typography, spacing, colors, dark-mode check across calendar, list, sheet, and button

## 6. Verification

- [x] 6.1 Run all unit tests and fix failures
- [x] 6.2 Manual end-to-end pass on the simulator: log strength and cardio series, delete one, finish the day, relaunch the app, and confirm persistence and calendar highlight (automated as `gymappUITests/testLogWorkoutEndToEnd`)
