# workout-logging Specification (Delta)

## MODIFIED Requirements

### Requirement: Exercise selection
The logging screen SHALL provide an exercise picker presented as a searchable sheet listing all exercises from the exercise catalog (see `exercise-catalog`), with case- and diacritic-insensitive name search and filters by primary muscle and equipment. Rows MUST show the exercise thumbnail (or category-icon fallback) and display name. Selecting an exercise MUST open the set-entry popup for that exercise.

#### Scenario: Selecting an exercise
- **WHEN** the user opens the exercise picker and selects an exercise
- **THEN** the set-entry popup opens for that exercise

#### Scenario: Searching within the picker
- **WHEN** the user types "press" in the picker's search field
- **THEN** only exercises whose display name matches "press" (ignoring case and diacritics) remain listed

#### Scenario: Filtering within the picker
- **WHEN** the user filters the picker by equipment `dumbbell`
- **THEN** only dumbbell exercises remain listed
