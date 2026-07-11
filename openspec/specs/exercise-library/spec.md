# exercise-library Specification

## Purpose
Provide an Exercises root tab where the user can browse the full exercise catalog alphabetically by localized name, search it with case- and diacritic-insensitive matching, and navigate to any exercise's detail screen.

## Requirements

### Requirement: Exercises library tab
The app SHALL provide an "Exercises" root tab that lists every exercise in the catalog, sorted alphabetically by localized display name using locale-aware comparison. Each row MUST show the exercise's localized name, an icon indicating its category (strength or cardio), and its primary muscle-target metadata as localized labels.

#### Scenario: Browsing the full catalog
- **WHEN** the user opens the Exercises tab
- **THEN** all catalog exercises are listed alphabetically by localized name, each row showing the name, a category icon, and the exercise's primary muscles

#### Scenario: Ordering follows the device locale
- **WHEN** the device language is Spanish and the Exercises tab is opened
- **THEN** the list is ordered by Spanish display names, even where that order differs from the English ordering

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
