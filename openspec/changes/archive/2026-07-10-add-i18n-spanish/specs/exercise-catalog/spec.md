# exercise-catalog Specification (delta)

## ADDED Requirements

### Requirement: Localized exercise display names
Exercise display names SHALL be resolved at render time from the exercise's stable unique `id` via the localization system, with the stored name as fallback. The stored `name` remains the canonical (English) value in the persistent store; muscle-target metadata and category are unaffected by localization. An exercise whose `id` has no localization entry MUST display its stored name unchanged.

#### Scenario: Catalog exercise on a Spanish device
- **WHEN** a bundled exercise (e.g. id `bench-press`) is displayed in the picker, series rows, set-entry title, or routine summaries on a Spanish device
- **THEN** its Spanish display name is shown (e.g. "Press de banca") while the stored name and muscle-target metadata remain unchanged

#### Scenario: Unknown id falls back to stored name
- **WHEN** an exercise whose id has no entry in the localization table is displayed
- **THEN** its stored name is shown as-is

## MODIFIED Requirements

### Requirement: Catalog query for selection UI
The app SHALL expose the catalog sorted alphabetically by localized display name, using locale-aware comparison for the current device language, for display in selection controls.

#### Scenario: Exercise list for the dropdown
- **WHEN** the logging screen requests the exercise list
- **THEN** all catalog exercises are returned sorted alphabetically by their localized display name under the current locale

#### Scenario: Spanish ordering differs from English
- **WHEN** the device language is Spanish and the exercise list is requested
- **THEN** exercises are ordered by their Spanish display names, even where that order differs from the English ordering
