# Tasks — add-exercise-detail-screen

## 1. Catalog content source

- [x] 1.1 Add `CatalogExercise` Codable DTO (id, name, category, primaryMuscles, secondaryMuscles, summary, instructions) and `ExerciseCatalogSource` protocol; implement `BundledCatalogSource` decoding `exercises.json`; unit tests decode the current file (missing summary/instructions tolerated until 1.2)
- [x] 1.2 Author English `summary` and 3–5 `instructions` steps for the first 20 exercises in `exercises.json` (chest, back/lats/traps, shoulders)
- [x] 1.3 Author English `summary` and `instructions` for the remaining 20 exercises (arms, core, legs, cardio); make DTO fields required and update the decoding test

## 2. Model and seeding

- [x] 2.1 Extend `Exercise` with defaulted stored properties `summary: String`, `instructionSteps: [String]`, `isUserModified: Bool`; add `localizedSummary`/`localizedInstructionSteps` resolving from the `ExerciseContent` table by id with stored-value fallback; make `localizedName` return the stored name when `isUserModified` is true
- [x] 2.2 Refactor `CatalogSeeder` to consume `ExerciseCatalogSource`; add an idempotent backfill pass that fills new fields on existing non-user-modified exercises and never touches user-modified ones; unit tests: fresh seed, upgrade backfill, idempotency, user-edit preservation

## 3. Localized exercise content

- [x] 3.1 Create `ExerciseContent.xcstrings` with English source entries for all 40 exercises (`exercise.<id>.summary`, `exercise.<id>.step.<n>`)
- [x] 3.2 Add Spanish translations for the first 20 exercises' summaries and steps
- [x] 3.3 Add Spanish translations for the remaining 20 exercises; extend the localization completeness unit test so every catalog id must have Spanish summary and step entries

## 4. Exercises library tab

- [x] 4.1 Build `ExerciseLibraryView` (alphabetical locale-aware list; rows with localized name, category icon, primary-muscle chips) and add the "Exercises" tab with its own `NavigationStack` to `RootTabView`; localize all new UI strings in en/es
- [x] 4.2 Add `.searchable` filtering with `localizedStandardContains` (case/diacritic-insensitive) and a localized no-results empty state; UI test: browse, search narrows list, tap navigates to detail

## 5. Exercise detail screen

- [x] 5.1 Build `ExerciseDetailView` read-only layout: header with localized name and category icon, description section, numbered instruction steps; sections hidden when content is empty; navigation wired from the library by exercise id
- [x] 5.2 Add the muscle-target visualization: primary muscles as emphasized chips, secondary as muted chips, localized names, secondary row omitted when empty
- [x] 5.3 Implement `ExerciseHistoryProvider` as pure aggregation over `WorkoutSeries`: last-performed date, best set (strength: heaviest weight with reps tie-break, bodyweight fallback to most reps; cardio: longest duration), 5 most recent sessions; unit tests for each rule and the empty case
- [x] 5.4 Add the history section UI with localized formatting (weights, reps, durations, dates) and the never-performed empty state
- [x] 5.5 Add the related-exercises section: shared primary muscle, excluding self, alphabetical, capped at 6, hidden when empty; cards navigate to their own detail screens

## 6. Edit mode

- [x] 6.1 Build the edit form toggled by the detail screen's Edit button: pre-filled with resolved (displayed) values; name field, category picker, primary/secondary muscle multi-select, description editor, instruction steps with add/remove/reorder; Cancel restores read-only view unchanged
- [x] 6.2 Implement Save: validation (non-empty name, at least one primary muscle, id immutable), persist all fields, set `isUserModified`; unit tests: override semantics (stored values win everywhere), validation rejections, edits survive reseeding
- [x] 6.3 UI test: edit flow — rename an exercise, save, verify the new name in the library, detail, and Add Exercise menu, and after relaunch; cancel discards changes

## 7. Verification

- [x] 7.1 Run the full unit and UI test suites in English and Spanish, walk through every spec scenario manually in the simulator, and run `openspec validate add-exercise-detail-screen`
