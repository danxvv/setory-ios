# exercise-detail Specification (Delta)

## MODIFIED Requirements

### Requirement: Exercise detail content
The exercise detail screen SHALL display, for a single exercise: its display name, a category icon (strength or cardio), its localized equipment label when equipment metadata exists, a localized description, and localized step-by-step instructions rendered as an ordered list. Description and instructions MUST resolve through the per-locale content stored with the exercise (user-modified values verbatim; the current language's variant when present; canonical English otherwise). Sections without content MUST be omitted (no empty placeholders or broken layout).

#### Scenario: Detail for a catalog exercise on a Spanish device
- **WHEN** the user opens the detail screen for a catalog exercise on a Spanish device
- **THEN** the screen shows the exercise's name, category icon, Spanish equipment label, Spanish description, and Spanish instruction steps in order

#### Scenario: Exercise without content hides gracefully
- **WHEN** an exercise has no description, no instruction steps, or no equipment metadata
- **THEN** the corresponding section or label is omitted

## ADDED Requirements

### Requirement: Media section
The exercise detail screen SHALL display a media section for exercises with a media reference, showing the animated demonstration when available and degrading per the `exercise-media` capability (thumbnail plus retry affordance), with the Gym visual attribution visible. Exercises without a media reference MUST NOT show a media section.

#### Scenario: Media section for a catalog exercise
- **WHEN** the user opens the detail screen of a catalog exercise
- **THEN** the media section appears above the descriptive content with the animated demonstration (or its documented fallback) and the attribution string

#### Scenario: No media section without media
- **WHEN** the user opens the detail screen of an exercise without a media reference
- **THEN** no media section, placeholder, or attribution row is rendered
