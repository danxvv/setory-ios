# exercise-library Specification

## Purpose
Provide an Exercises root tab where the user can browse the full exercise catalog alphabetically by localized name, search it with case- and diacritic-insensitive matching, and navigate to any exercise's detail screen.

## Requirements

### Requirement: Exercises library tab
The app SHALL provide an "Exercises" root tab that lists every exercise in the catalog, sorted alphabetically by display name using locale-aware comparison. Each row MUST show the exercise's thumbnail (or category-icon fallback for exercises without media), its display name, and its primary muscle-target metadata as localized labels. The list MUST remain responsive at full catalog size (1,300+ exercises).

#### Scenario: Browsing the full catalog
- **WHEN** the user opens the Exercises tab
- **THEN** all catalog exercises are listed alphabetically by display name, each row showing a thumbnail, the name, and the exercise's primary muscles

#### Scenario: Row without media
- **WHEN** an exercise without a media reference appears in the list
- **THEN** its row shows the category icon in place of a thumbnail

### Requirement: Library filters
The Exercises tab SHALL provide filters by primary muscle and by equipment, combinable with each other and with the search text. Active filters MUST be visible and individually clearable, and an empty filtered result MUST show the localized empty state.

#### Scenario: Filter by muscle
- **WHEN** the user filters by `chest`
- **THEN** only exercises whose primary muscles include chest remain listed

#### Scenario: Combined filter and search
- **WHEN** the user filters by equipment `dumbbell` and searches "press"
- **THEN** only dumbbell exercises whose display name matches "press" (case- and diacritic-insensitive) remain listed

#### Scenario: Clearing filters restores the full list
- **WHEN** the user clears all active filters and the search text
- **THEN** the full catalog list is shown again

### Requirement: Exercise search
The Exercises tab SHALL provide a search field that filters the list by localized display name. Matching MUST be case-insensitive and diacritic-insensitive.

#### Scenario: Search narrows the list
- **WHEN** the user types "press" into the search field
- **THEN** only exercises whose localized name contains "press" (ignoring case and diacritics) remain listed

#### Scenario: No matches shows an empty state
- **WHEN** the search text matches no exercise
- **THEN** a localized empty state is shown instead of the list

### Requirement: Navigation to exercise detail
Tapping an exercise row SHALL navigate to that exercise's detail screen within the tab's navigation stack.

#### Scenario: Opening a detail screen
- **WHEN** the user taps "Bench Press" in the Exercises list
- **THEN** the exercise detail screen for `bench-press` is pushed onto the navigation stack
