# workout-logging Specification

## Purpose
Provide the workout logging screen: a calendar for selecting days, exercise selection with a set-entry popup, an ordered list of the day's series, the ability to start a day from a routine template, and a "Finish Day" action that persists the session locally.

## Requirements

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

### Requirement: Set-entry popup
The set-entry popup SHALL adapt its inputs to the exercise category: for `strength` exercises it MUST accept repetitions (required, positive integer) and weight (optional, non-negative decimal in kg); for `cardio` exercises it MUST accept a duration (required, greater than zero). The popup SHALL offer confirm and cancel actions, and confirm MUST be disabled while required inputs are missing or invalid.

#### Scenario: Entering a strength set
- **WHEN** the user selects a strength exercise and enters 10 reps at 40 kg and confirms
- **THEN** the popup closes and a series with 10 reps and 40 kg is appended to the day's list

#### Scenario: Entering a cardio set
- **WHEN** the user selects a cardio exercise and enters a duration of 15 minutes and confirms
- **THEN** the popup closes and a series with a 15-minute duration is appended to the day's list

#### Scenario: Invalid input blocks confirmation
- **WHEN** the required field (reps or duration) is empty or not a positive value
- **THEN** the confirm action is disabled

#### Scenario: Cancelling entry
- **WHEN** the user cancels the popup
- **THEN** the popup closes and no series is added

### Requirement: Day series list
The logging screen SHALL display the series recorded for the selected day as an ordered list in the order they were added. Each row MUST show the exercise name and its recorded values (reps and weight, or duration). The user SHALL be able to add multiple series of the same or different exercises and to remove a series before the day is finished.

#### Scenario: Accumulating series
- **WHEN** the user confirms several set entries across one or more exercises
- **THEN** each appears as a new row in the list in the order it was added

#### Scenario: Removing a series
- **WHEN** the user deletes a series from the list before finishing the day
- **THEN** the series is removed from the list and is not saved

### Requirement: Finish Day saves the session
The logging screen SHALL show a "Finish Day" button at the bottom whenever the selected day has at least one unsaved series. Tapping it MUST persist the accumulated series as the selected day's workout session (routine) in local storage, after which the day appears highlighted in the calendar. Saved sessions MUST survive app restarts.

#### Scenario: Saving the day
- **WHEN** the user has added at least one series and taps "Finish Day"
- **THEN** the session is saved for the selected day, the calendar highlights that day, and the screen reflects the saved state

#### Scenario: No series, no button
- **WHEN** the selected day has no unsaved series
- **THEN** the "Finish Day" button is not shown (or is disabled)

#### Scenario: Persistence across restarts
- **WHEN** the user saves a day and relaunches the app
- **THEN** the saved session and its calendar highlight are still present

### Requirement: Apply routine template to a day
The logging screen SHALL let the user apply a routine template (see `routine-templates`) to the selected day when that day has no saved session. Applying stages the template's exercises as a plan section: each planned exercise MUST show its localized name, logged-versus-target set progress derived from the day's draft series, and the user's most recent recorded values for that exercise as a reference when history exists. Tapping a planned exercise MUST open the set-entry popup for it, and each saved set counts toward that exercise's progress. The plan is guidance only: "Finish Day" MUST persist only actually logged series, and the plan itself is never persisted. Applying a template to a day that already has a plan MUST replace it only after confirmation; applying MUST be unavailable on days with a saved session. Planned items whose exercise is missing MUST be skipped.

#### Scenario: Starting a day from a template
- **WHEN** the user applies the "Push Day" template (bench press ×4, triceps pushdown ×3) to an empty day
- **THEN** a plan section lists bench press with 0/4 sets and triceps pushdown with 0/3 sets in template order

#### Scenario: Logged sets advance plan progress
- **WHEN** the plan shows bench press 0/4 and the user logs two bench press sets via the set-entry popup
- **THEN** the plan shows bench press 2/4 while the two sets appear in the day's series list

#### Scenario: Last performance is shown as reference
- **WHEN** a planned exercise was previously recorded (e.g. most recently 60 kg × 8)
- **THEN** its plan row shows those most recent values as a reference, and rows for never-performed exercises show no reference

#### Scenario: Finishing the day ignores unmet targets
- **WHEN** the user finishes a day whose plan shows bench press 2/4
- **THEN** the saved session contains exactly the 2 logged bench press series and no empty placeholder series

#### Scenario: Replacing an existing plan requires confirmation
- **WHEN** the user applies a template to a day that already has a plan
- **THEN** a confirmation is required, and confirming replaces the previous plan without touching already-logged draft series

#### Scenario: Saved days cannot receive a template
- **WHEN** the selected day already has a saved workout session
- **THEN** no apply-template action is offered for that day

### Requirement: Routine media on the logging screen
Every routine row on the logging screen — planned exercise rows, unsaved draft series rows, and saved-session series rows — SHALL show the exercise's bundled thumbnail, falling back to the exercise's category icon when the exercise has no media reference, and to a neutral placeholder icon when the row's exercise is missing (e.g. deleted). For exercises with a media reference, the thumbnail SHALL act as an affordance that opens a media viewer presenting that exercise's animated demonstration with the exercise's localized name, per the `exercise-media` capability (on-demand fetch, on-disk cache, thumbnail degradation with retry, and attribution). Opening the viewer MUST NOT trigger the row's primary action (set-entry popup or routine-detail navigation), and all existing row interactions (row tap, swipe-to-delete) MUST continue to work. Exercises without a media reference MUST NOT offer the viewer affordance. This requirement changes presentation only: it MUST NOT alter what is logged or saved, nor the exercises' muscle-target metadata.

#### Scenario: Plan rows show thumbnails
- **WHEN** the user applies a routine template to an empty day
- **THEN** each planned exercise row shows the exercise's thumbnail (or category-icon fallback) alongside its name, progress, and reference values

#### Scenario: Series rows show thumbnails
- **WHEN** the selected day has draft series or a saved session
- **THEN** each series row shows the exercise's thumbnail (or category-icon fallback) alongside its name and recorded values

#### Scenario: Thumbnail opens the animated demonstration
- **WHEN** the user taps the thumbnail of a routine exercise that has a media reference
- **THEN** a media viewer opens showing that exercise's animated demonstration and name, and the row's primary action is not triggered

#### Scenario: Row actions keep working alongside media
- **WHEN** the user taps a planned exercise row outside its thumbnail
- **THEN** the set-entry popup opens as before, and no media viewer appears

#### Scenario: Exercise without media offers no viewer
- **WHEN** a routine row's exercise has no media reference
- **THEN** the row shows the category icon in place of a thumbnail and tapping it does not open the media viewer

#### Scenario: Saved series with a missing exercise
- **WHEN** a saved-session series row's exercise no longer exists
- **THEN** the row shows a placeholder icon, offers no viewer affordance, and its name and values render as before
