# exercise-catalog Delta Spec

## ADDED Requirements

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

## MODIFIED Requirements

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
