# exercise-catalog Specification

## Purpose
Provide a bundled catalog of predefined exercises, with category and muscle-target metadata, that the app seeds into local storage and exposes to selection UIs.

## Requirements

### Requirement: Bundled exercise catalog
The app SHALL ship with a bundled catalog of predefined exercises. Each exercise MUST have a unique identifier, a display name, a category (`strength` or `cardio`), and muscle-target metadata consisting of at least one primary muscle and zero or more secondary muscles. Exercises without muscle-target metadata MUST NOT exist in the catalog.

#### Scenario: Catalog is available on first launch
- **WHEN** the app launches for the first time
- **THEN** the exercise catalog is seeded into the local store and every exercise exposes its name, category, primary muscles, and secondary muscles

#### Scenario: Seeding is idempotent
- **WHEN** the app launches and the catalog has already been seeded
- **THEN** no duplicate exercises are created

### Requirement: Catalog covers both measurement types
The catalog SHALL classify every exercise so the UI can determine its input mode: `strength` exercises are measured in repetitions with optional weight; `cardio` exercises are measured in elapsed time.

#### Scenario: Strength exercise classification
- **WHEN** a strength exercise (e.g., bench press) is read from the catalog
- **THEN** its category indicates rep/weight-based measurement

#### Scenario: Cardio exercise classification
- **WHEN** a cardio exercise (e.g., treadmill run) is read from the catalog
- **THEN** its category indicates time-based measurement

### Requirement: Catalog query for selection UI
The app SHALL expose the catalog sorted alphabetically by localized display name, using locale-aware comparison for the current device language, for display in selection controls.

#### Scenario: Exercise list for the dropdown
- **WHEN** the logging screen requests the exercise list
- **THEN** all catalog exercises are returned sorted alphabetically by their localized display name under the current locale

#### Scenario: Spanish ordering differs from English
- **WHEN** the device language is Spanish and the exercise list is requested
- **THEN** exercises are ordered by their Spanish display names, even where that order differs from the English ordering

### Requirement: Localized exercise display names
Exercise display names SHALL be resolved at render time from the exercise's stable unique `id` via the localization system, with the stored name as fallback. The stored `name` remains the canonical (English) value in the persistent store; muscle-target metadata and category are unaffected by localization. An exercise whose `id` has no localization entry MUST display its stored name unchanged. An exercise marked user-modified MUST display its stored name verbatim, bypassing the localization catalog entirely.

#### Scenario: Catalog exercise on a Spanish device
- **WHEN** a bundled exercise (e.g. id `bench-press`) is displayed in the picker, series rows, set-entry title, or routine summaries on a Spanish device
- **THEN** its Spanish display name is shown (e.g. "Press de banca") while the stored name and muscle-target metadata remain unchanged

#### Scenario: Unknown id falls back to stored name
- **WHEN** an exercise whose id has no entry in the localization table is displayed
- **THEN** its stored name is shown as-is

#### Scenario: User-modified exercise bypasses the catalog translation
- **WHEN** a user-modified exercise whose id still has a localization entry is displayed on any device language
- **THEN** its stored (user-entered) name is shown instead of the catalog translation

### Requirement: Exercise descriptions and instructions
Every exercise in the bundled catalog SHALL include a description (what the exercise is and what it trains, consistent with its muscle-target metadata) and at least one step-by-step instruction. The canonical (English) description and instruction steps are stored with the exercise; localized variants resolve at display time by stable exercise `id`. Muscle-target metadata, category, and `id` remain the locale-independent serialization values.

#### Scenario: Seeded exercises carry content
- **WHEN** the catalog is seeded on first launch
- **THEN** every exercise exposes a non-empty description and a non-empty ordered list of instruction steps

#### Scenario: Upgrade backfills existing stores
- **WHEN** the app launches with a store seeded before descriptions and instructions existed
- **THEN** every previously seeded, non-user-modified exercise is backfilled with the catalog's description and instruction steps, without creating duplicates

#### Scenario: Backfill preserves user edits
- **WHEN** the seeder runs and an exercise is marked user-modified
- **THEN** that exercise's fields are left untouched

### Requirement: Swappable catalog content source
The catalog SHALL be loaded through a data-source abstraction that yields exercise entries (id, name, category, primary muscles, secondary muscles, description, instruction steps). The current implementation reads the bundled JSON; the abstraction's entry shape defines the payload contract a future REST catalog endpoint must return, so replacing the source must not require UI or seeding-logic changes.

#### Scenario: Seeding consumes the abstraction
- **WHEN** the catalog seeder runs
- **THEN** it obtains all exercise entries, including descriptions and instruction steps, exclusively through the catalog source abstraction backed by the bundled JSON
