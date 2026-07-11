# workout-logging Delta Specification

## MODIFIED Requirements

### Requirement: Calendar header
The logging screen SHALL display a calendar at the top showing the current month. The calendar MUST highlight days that have a saved workout session and MUST indicate the selected day, which defaults to today. The user SHALL be able to navigate between months and select a day to view or log that day's workout. When the selected day has a saved session, the saved-series section MUST offer navigation to that session's routine detail view (see `routine-history`).

#### Scenario: Default selection is today
- **WHEN** the logging screen opens
- **THEN** the calendar shows the current month with today selected

#### Scenario: Saved days are highlighted
- **WHEN** the calendar displays a month containing days with saved workout sessions
- **THEN** each such day shows a visual marker distinct from unsaved days

#### Scenario: Selecting a day with a saved session
- **WHEN** the user selects a day that already has a saved workout session
- **THEN** the list below shows that day's saved series

#### Scenario: Opening the routine detail from a saved day
- **WHEN** the user selects a day with a saved session and taps the saved-workout section's navigation link
- **THEN** the routine detail view for that day's session is pushed
