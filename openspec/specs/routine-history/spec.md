# routine-history Specification

## Purpose
Provide browsing of saved routines and access to routine templates: a Routines screen with a Templates section (see `routine-templates`) above a History section listing all saved workout sessions newest first, a per-session detail view with the recorded series, muscle-target information, and a "Save as template" action, and compact empty states when a section has no content.

## Requirements

### Requirement: Routines list screen
The app SHALL provide a "Routines" screen, reachable as a top-level tab alongside the logging screen, that hosts two sections: a Templates section listing the user's routine templates (see `routine-templates`) followed by a History section listing all saved workout sessions sorted by date descending (newest first). Each template row MUST show the template's name, its exercise count, and its muscle coverage, and MUST navigate to that template's detail/editor; the Templates section MUST offer an action to create a new template. Each history row MUST show the session's date, the number of series it contains, and the names of the exercises involved. When a section has no content, it MUST show a compact localized empty state within the section — for History, explaining that finished days appear here.

#### Scenario: Listing saved routines
- **WHEN** the user opens the Routines tab and at least one workout session has been saved
- **THEN** the History section lists all saved sessions newest first, each showing its date, series count, and exercise names

#### Scenario: Templates section lists templates
- **WHEN** the user opens the Routines tab and at least one template exists
- **THEN** the Templates section appears above History, each row showing the template's name, exercise count, and muscle coverage, and tapping a row opens that template

#### Scenario: Creating a template from the Routines tab
- **WHEN** the user taps the Templates section's create action
- **THEN** the template editor opens for a new template

#### Scenario: Empty state
- **WHEN** the user opens the Routines tab and no workout session has been saved
- **THEN** the History section shows an empty state indicating that saved routines will appear here after finishing a day

#### Scenario: Empty templates state
- **WHEN** the user opens the Routines tab and no template exists
- **THEN** the Templates section shows a compact empty state inviting the user to create one

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

### Requirement: Save session as template action
The routine detail view SHALL offer a "Save as template" action that starts template creation pre-filled from the session, as specified in `routine-templates` (Create template from saved session).

#### Scenario: Action is available on a saved session
- **WHEN** the user opens the detail view of a saved session
- **THEN** a "Save as template" action is available and opens the pre-filled template editor
