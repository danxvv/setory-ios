## 1. Media viewer sheet

- [x] 1.1 Create `gymapp/Views/RoutineMediaSheet.swift`: a `NavigationStack` wrapping `ExerciseMediaView(exercise:)` with the exercise's localized name as the title and a Done button that dismisses the sheet
- [x] 1.2 Add accessibility identifiers to the sheet and its media area so UI tests can assert the viewer opened for the right exercise

## 2. Main-page row integration (ContentView)

- [x] 2.1 Add `@State private var mediaExercise: Exercise?` and a `.sheet(item:)` presenting `RoutineMediaSheet` to `ContentView`
- [x] 2.2 Plan rows (`plannedRow`): add `ExerciseThumbnailView(exercise:size:)` wrapped in a `.borderless` button (gated on `exercise.hasMedia`) that sets `mediaExercise`; verify the row tap still opens the set-entry popup
- [x] 2.3 Refactor `seriesRow(name:summary:index:)` to also receive the `Exercise?` and render the thumbnail with the same tap affordance; update the saved-session and draft call sites
- [x] 2.4 Handle the missing-exercise case (`WorkoutSeries.exercise == nil`): placeholder icon, no tap affordance, unchanged text; verify swipe-to-delete on draft rows still works

## 3. Localization

- [x] 3.1 Add the new user-facing strings (Done button if needed, "Show demonstration for %@"-style accessibility labels) to `Localizable.xcstrings` with Spanish translations, and run `LocalizationTests` to confirm completeness

## 4. Tests

- [x] 4.1 UI test: apply a template, assert plan rows show thumbnails, tapping a thumbnail opens the media viewer (and not the set-entry popup), and tapping the row elsewhere still opens the popup
- [x] 4.2 UI test: draft and saved-session series rows show thumbnails; with the network-disabled launch flag, the viewer degrades to the bundled thumbnail with a retry affordance and no error alert
- [x] 4.3 Update any existing workout-logging UI tests affected by the new row layout or accessibility identifiers

## 5. Verification

- [x] 5.1 Build and run the full unit + UI test suites (xcodebuild with the project's scratch derivedDataPath workflow) and fix any regressions
