# exercise-detail Specification

## Purpose
Provide a per-exercise detail screen that shows localized content (name, category, description, step-by-step instructions), visualizes primary and secondary muscle targets, summarizes the user's personal history and best set for the exercise, and links to related exercises that share a primary muscle.

## Requirements

### Requirement: Exercise detail content
The exercise detail screen SHALL display, for a single exercise: its localized display name, a category icon (strength or cardio), a localized description, and localized step-by-step instructions rendered as an ordered list. Description and instructions MUST resolve through the localization system for catalog exercises and MUST fall back to the stored values when no localization entry exists (e.g. user-modified exercises).

#### Scenario: Detail for a catalog exercise
- **WHEN** the user opens the detail screen for `bench-press` on a Spanish device
- **THEN** the screen shows the Spanish name, the strength category icon, the Spanish description, and the Spanish instruction steps in order

#### Scenario: Exercise without content hides gracefully
- **WHEN** an exercise has no description or no instruction steps
- **THEN** the corresponding section is omitted (no empty placeholders or broken layout)

### Requirement: Muscle-target visualization
The detail screen SHALL display the exercise's muscle-target metadata with primary and secondary muscles visually distinct (primary emphasized, secondary muted) and labeled with localized muscle names.

#### Scenario: Primary and secondary muscles distinguished
- **WHEN** the detail screen for `deadlift` is displayed
- **THEN** its primary muscles (back, hamstrings) appear emphasized and its secondary muscles (glutes, lower back, traps, forearms) appear muted, all with localized names

#### Scenario: Exercise with no secondary muscles
- **WHEN** the detail screen for an exercise with zero secondary muscles is displayed
- **THEN** only the primary muscle group is shown, with no empty secondary section

### Requirement: Personal history and records
The detail screen SHALL summarize the user's local workout history for the exercise: the date it was last performed, the best set, and the most recent sessions (up to 5) with their set values. The best set MUST be computed as: for strength exercises, the set with the highest weight (ties broken by repetitions), falling back to the most repetitions when no set has a weight; for cardio exercises, the longest duration. When the exercise has never been performed, a localized empty state MUST be shown instead.

#### Scenario: History for a performed strength exercise
- **WHEN** the user opens the detail screen for an exercise logged in past sessions with weighted sets
- **THEN** the screen shows the last-performed date, the heaviest set as the best set, and up to 5 recent sessions with their set values

#### Scenario: Best set for bodyweight strength exercise
- **WHEN** every logged set of a strength exercise has repetitions but no weight
- **THEN** the set with the most repetitions is shown as the best set

#### Scenario: Best set for cardio exercise
- **WHEN** the user opens the detail screen for a cardio exercise with logged time-based sets
- **THEN** the longest duration is shown as the best set

#### Scenario: Never performed
- **WHEN** the user opens the detail screen for an exercise absent from all workout sessions
- **THEN** a localized empty state indicates the exercise has not been performed yet

### Requirement: Related exercises
The detail screen SHALL list other exercises that share at least one primary muscle with the displayed exercise, excluding the exercise itself, sorted alphabetically by localized name and capped at 6 entries. Each related exercise MUST navigate to its own detail screen. When no exercise shares a primary muscle, the section MUST be hidden.

#### Scenario: Related exercises by shared primary muscle
- **WHEN** the detail screen for `bench-press` (primary: chest) is displayed
- **THEN** other chest-primary exercises (e.g. push-up, dumbbell fly) are listed, and tapping one opens its detail screen

#### Scenario: No related exercises
- **WHEN** no other exercise shares a primary muscle with the displayed exercise
- **THEN** the related-exercises section is not shown

### Requirement: Navigation to exercise progression
The exercise detail screen's personal-history section SHALL offer navigation to the exercise's progression screen (see `progress-stats`) when the exercise has at least one logged series. When the exercise has never been performed, no progression link is shown.

#### Scenario: Link shown for performed exercise
- **WHEN** the user views the detail screen of an exercise with logged history
- **THEN** the history section shows a localized link that pushes the exercise's progression screen

#### Scenario: No link without history
- **WHEN** the user views the detail screen of an exercise that has never been performed
- **THEN** no progression link is displayed
