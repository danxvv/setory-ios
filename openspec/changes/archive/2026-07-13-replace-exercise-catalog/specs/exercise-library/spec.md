# exercise-library Specification (Delta)

## MODIFIED Requirements

### Requirement: Exercises library tab
The app SHALL provide an "Exercises" root tab that lists every exercise in the catalog, sorted alphabetically by display name using locale-aware comparison. Each row MUST show the exercise's thumbnail (or category-icon fallback for exercises without media), its display name, and its primary muscle-target metadata as localized labels. The list MUST remain responsive at full catalog size (1,300+ exercises).

#### Scenario: Browsing the full catalog
- **WHEN** the user opens the Exercises tab
- **THEN** all catalog exercises are listed alphabetically by display name, each row showing a thumbnail, the name, and the exercise's primary muscles

#### Scenario: Row without media
- **WHEN** an exercise without a media reference appears in the list
- **THEN** its row shows the category icon in place of a thumbnail

## ADDED Requirements

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
