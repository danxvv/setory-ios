# exercise-detail Specification (delta)

## ADDED Requirements

### Requirement: Navigation to exercise progression
The exercise detail screen's personal-history section SHALL offer navigation to the exercise's progression screen (see `progress-stats`) when the exercise has at least one logged series. When the exercise has never been performed, no progression link is shown.

#### Scenario: Link shown for performed exercise
- **WHEN** the user views the detail screen of an exercise with logged history
- **THEN** the history section shows a localized link that pushes the exercise's progression screen

#### Scenario: No link without history
- **WHEN** the user views the detail screen of an exercise that has never been performed
- **THEN** no progression link is displayed
