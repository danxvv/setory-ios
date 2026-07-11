# routine-history Delta Specification

## ADDED Requirements

### Requirement: Routines list screen
The app SHALL provide a "Routines" screen, reachable as a top-level tab alongside the logging screen, that lists all saved workout sessions sorted by date descending (newest first). Each row MUST show the session's date, the number of series it contains, and the names of the exercises involved. When no sessions have been saved, the screen MUST show an empty state explaining that finished days appear here.

#### Scenario: Listing saved routines
- **WHEN** the user opens the Routines tab and at least one workout session has been saved
- **THEN** all saved sessions are listed newest first, each showing its date, series count, and exercise names

#### Scenario: Empty state
- **WHEN** the user opens the Routines tab and no workout session has been saved
- **THEN** an empty state is shown indicating that saved routines will appear here after finishing a day

### Requirement: Routine detail view
The app SHALL provide a detail view for a single saved workout session showing its series as an ordered list in their recorded order. Each row MUST show the exercise name and its recorded values (reps and optional weight in kg, or duration). The detail view MUST surface the muscle-target metadata of the session's exercises: each series row (or its exercise) SHALL indicate the exercise's primary muscles, and the view SHALL show a summary of the muscles worked in the session. If a series has no associated exercise, the row MUST show a placeholder name and omit muscle information.

#### Scenario: Viewing a routine's series
- **WHEN** the user opens the detail view of a saved session
- **THEN** the session's series are listed in order with exercise names and their recorded values

#### Scenario: Muscle targets are visible
- **WHEN** the detail view displays a series whose exercise has muscle-target metadata
- **THEN** the exercise's primary muscles are indicated, and the view shows a summary of muscles worked in the session

#### Scenario: Missing exercise fallback
- **WHEN** a series in the session has no associated exercise
- **THEN** the row shows a placeholder name and no muscle information

### Requirement: Navigation from list to detail
Tapping a routine row on the Routines list screen SHALL navigate to that session's routine detail view.

#### Scenario: Opening a routine from the list
- **WHEN** the user taps a session row on the Routines list
- **THEN** the routine detail view for that session is pushed
