## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Save session as template action
The routine detail view SHALL offer a "Save as template" action that starts template creation pre-filled from the session, as specified in `routine-templates` (Create template from saved session).

#### Scenario: Action is available on a saved session
- **WHEN** the user opens the detail view of a saved session
- **THEN** a "Save as template" action is available and opens the pre-filled template editor
