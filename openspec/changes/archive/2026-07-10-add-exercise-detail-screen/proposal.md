# Add Exercise Detail Screen

## Why

Exercises in the app are currently just names in a picker menu — there is no way to browse the catalog or learn what an exercise is, how to perform it, or what muscles it targets. A detail screen makes the muscle-target metadata (already the core of the domain model) visible and useful to the user, surfaces personal history for each exercise, and creates the natural place for editing exercise data as the catalog grows toward a REST-backed source.

## What Changes

- Add a new **Exercises library tab**: a browsable, searchable list of every catalog exercise, the entry point to detail screens.
- Add an **exercise detail screen** showing, for one exercise:
  - Category and muscle icons (handy visual badges).
  - A localized description of the exercise.
  - Localized step-by-step instructions.
  - A muscle-target visualization distinguishing primary from secondary muscles.
  - Personal workout history: last performed date, best set (max weight/reps for strength, longest duration for cardio), and recent sessions — from local SwiftData history.
  - Related exercises (same primary muscle), each navigating to its own detail screen.
- Extend the **bundled catalog content** (`exercises.json` + string catalogs) with description and instructions for every exercise, loaded through a data-source abstraction so a future REST API can replace the bundled JSON without UI changes.
- Add an **edit mode**: an Edit button turns the detail screen into an edit form where any exercise's name, category, muscles, description, and instructions can be changed and persisted locally. Renamed exercises must stop resolving their display name from the localization catalog so the user's name wins.

## Capabilities

### New Capabilities

- `exercise-library`: browsable, searchable list of all catalog exercises as a new root tab; entry point to exercise detail.
- `exercise-detail`: read-only detail screen for a single exercise — icons, description, instructions, muscle-target visualization, personal history/PRs, and related exercises.
- `exercise-editing`: in-place edit mode on the detail screen; full editing of any exercise's fields with local persistence and display-name override semantics.

### Modified Capabilities

- `exercise-catalog`: every catalog exercise gains description and step-by-step instructions content; catalog content is loaded through a swappable data source (bundled JSON now, REST later); localized display-name resolution must respect user renames (a renamed exercise shows its stored name, not the catalog translation).
- `localization`: description and instructions content must be fully localized in English and Spanish for every bundled exercise, alongside the existing name-completeness requirement.

## Impact

- **New views**: exercise library list view, exercise detail view, exercise edit form; `RootTabView` gains a third tab.
- **Model**: `Exercise` gains stored description/instructions (and a user-modified flag for rename override); SwiftData lightweight migration of existing stores; `CatalogSeeder` seeds and backfills the new fields.
- **Resources**: `exercises.json` extended with description/instructions; new/extended string catalog entries (`ExerciseNames.xcstrings` or a sibling table) with Spanish translations for all bundled content.
- **Services**: new catalog content data-source abstraction (protocol + bundled-JSON implementation) as the seam for the future REST API.
- **History queries**: read-only aggregation over existing `WorkoutSession`/`WorkoutSeries` data for last-performed/best-set/recent-sessions; no changes to workout logging behavior.
- **Tests**: unit tests for content loading, history aggregation, and rename override; UI tests for the new tab, detail navigation, and edit flow.
