## 1. Data model & helpers

- [x] 1.1 Add `RoutineTemplate` and `RoutineTemplateItem` SwiftData models (name, createdAt, cascade items; order, targetSets 1–10 default 3, optional `exercise` ref with inverse), plus `orderedItems`; register in the model container
- [x] 1.2 Add derived muscle coverage (`primaryMusclesCovered` / `secondaryMusclesCovered`) as pure static helpers on/next to `RoutineTemplate`, skipping nil exercises
- [x] 1.3 Add `TemplateNameSuggester` pure function (dominant primary muscles → "Chest & Triceps"; lower-body majority → "Leg Day"; all-cardio → "Cardio"; nil for empty input)
- [x] 1.4 Unit tests: template CRUD + cascade delete, ordering, muscle coverage derivation (incl. secondary-excludes-primary and nil-exercise items), name suggestion cases

## 2. Template editor

- [x] 2.1 Build `TemplateEditForm` (name field with suggested-name placeholder/pre-fill that never overwrites typed text, ordered exercise rows with target-sets stepper, reorder, swipe-delete, cancel/save with validation: non-empty trimmed name, ≥1 exercise)
- [x] 2.2 Build the multi-select "Add Exercises" picker sheet with localized-name sort and case/diacritic-insensitive search (reuse library search normalization)
- [x] 2.3 Unit tests for editor validation rules and save-from-draft mapping (items, order, targetSets)

## 3. Routines tab integration

- [x] 3.1 Restructure `RoutineListView` into Templates + History sections (template rows: name, exercise count, `MuscleChips`; compact per-section empty states; toolbar create action opening the editor)
- [x] 3.2 Add template detail/editor navigation, duplicate (context menu, localized "copy" suffix) and delete-with-confirmation
- [x] 3.3 Add "Save as template" action on `RoutineDetailView` pre-filling the editor from the session (dedup first-appearance order, targetSets = series count clamped 1–10, suggested name; nothing persisted on cancel)

## 4. Apply template on the logging screen

- [x] 4.1 Add `PlannedExercise` value type and per-day `plans` view state to `ContentView`; add the apply-template picker action (hidden for days with a saved session; replace-existing-plan confirmation)
- [x] 4.2 Render the plan section: template name header, rows with localized exercise name, logged/target progress derived from the day's drafts, "Last: …" reference via `ExerciseHistoryProvider` + `DraftSeries.summary`, tap → `SetEntrySheet`; skip nil-exercise items
- [x] 4.3 Verify Finish Day persists only logged drafts (unmet targets ignored) and plan/drafts clear correctly after save
- [x] 4.4 Unit tests for plan progress counting and plan staging from a template (incl. missing-exercise skip)

## 5. Localization & polish

- [x] 5.1 Add all new strings to `Localizable.xcstrings` with Spanish translations (sections, buttons, empty states, confirmations, suggested-name pieces like "Leg Day"/"Cardio"/copy suffix, plural-aware set counts)
- [x] 5.2 Audit the string catalogs for missing `es` values on new keys; verify suggested names and muscle chips render localized on a Spanish device/simulator

## 6. Verification

- [x] 6.1 UI test: create a template from the Routines tab, apply it on the Log tab, log a set from the plan, finish the day, and confirm the saved session contains only logged series
- [x] 6.2 Build and run full unit + UI test suites (scratch derivedDataPath workflow); fix regressions
- [x] 6.3 Manual pass: relaunch persistence of templates, lightweight migration from a store created by the current build, duplicate/delete flows, EN + ES walkthrough
