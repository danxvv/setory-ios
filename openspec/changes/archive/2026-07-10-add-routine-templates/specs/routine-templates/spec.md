## ADDED Requirements

### Requirement: Routine template creation
The app SHALL let the user create a named routine template consisting of an ordered list of exercises from the exercise catalog, each with a target set count between 1 and 10 (defaulting to 3). Exercise selection MUST reuse catalog data with localized names and case- and diacritic-insensitive search. Saving MUST be rejected while the trimmed name is empty or the template contains no exercises. Saved templates MUST persist locally and survive app relaunch.

#### Scenario: Creating a template
- **WHEN** the user creates a template named "Push Day" with bench press (4 sets), incline dumbbell press (3 sets), and triceps pushdown (3 sets), then saves
- **THEN** the template appears in the Templates section with its name and exercises in the chosen order, and it is still present after relaunching the app

#### Scenario: Empty name is rejected
- **WHEN** the user attempts to save a template whose name is empty or only whitespace
- **THEN** the save is blocked and the form indicates a name is required

#### Scenario: Template without exercises is rejected
- **WHEN** the user attempts to save a template with no exercises
- **THEN** the save is blocked and the form indicates at least one exercise is required

#### Scenario: Exercise picker is searchable
- **WHEN** the user types "press" (or "prés") in the template editor's exercise picker
- **THEN** only exercises whose localized name matches ignoring case and diacritics are offered

### Requirement: Routine template editing
The app SHALL let the user edit an existing template: rename it, add and remove exercises, reorder exercises, and change each exercise's target set count. Edits MUST be validated by the same rules as creation and MUST NOT take effect until saved; cancel discards all unsaved edits.

#### Scenario: Editing persists changes
- **WHEN** the user renames "Push Day" to "Chest Day", removes an exercise, reorders the remaining ones, changes a target set count, and saves
- **THEN** the template shows the updated name, order, and targets, and the changes survive relaunch

#### Scenario: Cancel discards edits
- **WHEN** the user modifies a template and cancels instead of saving
- **THEN** the template remains exactly as it was before editing

### Requirement: Template deletion and duplication
The app SHALL let the user delete a template after a confirmation prompt and duplicate a template. Duplication MUST copy the exercise list, order, and target set counts into a new template whose name is the original name with a localized "copy" suffix. Deleting a template MUST NOT affect saved workout sessions or the exercise catalog.

#### Scenario: Deleting a template
- **WHEN** the user deletes "Push Day" and confirms
- **THEN** the template disappears from the Templates section and previously saved workout sessions are unchanged

#### Scenario: Duplicating a template
- **WHEN** the user duplicates "Push Day"
- **THEN** a new template named with a localized copy suffix (e.g. "Push Day copy") appears containing the same exercises, order, and target sets, and can be edited independently

### Requirement: Muscle coverage summary
Every template SHALL display the muscles it works, derived from its exercises' muscle-target metadata: primary coverage is the union of the exercises' primary muscles in first-appearance order, and secondary coverage is the union of secondary muscles excluding those already covered as primary. Primary muscles MUST appear emphasized and secondary muscles muted, with localized muscle names. Coverage MUST be derived at display time so later exercise edits are reflected automatically.

#### Scenario: Coverage shown on template
- **WHEN** a template contains bench press (primary chest; secondary shoulders, triceps) and triceps pushdown (primary triceps)
- **THEN** the template shows chest and triceps as primary coverage and shoulders as secondary coverage, localized, with primary emphasized

#### Scenario: Coverage follows exercise edits
- **WHEN** the user edits an exercise's muscles and returns to a template containing it
- **THEN** the template's muscle coverage reflects the updated metadata without editing the template

### Requirement: Suggested template name
When creating a template (including from a saved session), the app SHALL offer a suggested name derived from the exercises' dominant primary-muscle profile (e.g. "Chest & Triceps"; a lower-body majority suggests a localized "Leg Day"; an all-cardio list suggests a localized "Cardio"). The suggestion MUST be an editable pre-fill or placeholder only: it MUST NOT overwrite a name the user has typed, and no suggestion is offered while the template has no exercises.

#### Scenario: Suggestion from dominant muscles
- **WHEN** the user has added bench press and triceps pushdown to a new unnamed template
- **THEN** the name field offers a localized suggestion built from chest and triceps, which the user can accept as-is or replace

#### Scenario: User-typed name is never overwritten
- **WHEN** the user has typed "My Monday Mix" and then adds or removes exercises
- **THEN** the typed name remains untouched

### Requirement: Create template from saved session
The routine detail view of a saved workout session SHALL offer an action that pre-fills the template editor from that session: exercises deduplicated in first-appearance order, each with a target set count equal to the number of series that exercise had in the session (clamped to 1–10), plus a suggested name. Nothing SHALL be persisted until the user saves from the editor.

#### Scenario: Saving a session as a template
- **WHEN** the user opens a saved session containing 4 series of bench press then 3 of triceps pushdown, chooses "Save as template", and saves the pre-filled editor
- **THEN** a new template exists with bench press (4 sets) followed by triceps pushdown (3 sets)

#### Scenario: Cancelling creates nothing
- **WHEN** the user chooses "Save as template" and then cancels the editor
- **THEN** no template is created

### Requirement: Missing exercise tolerance
Template items whose exercise reference is missing SHALL be skipped in display, muscle coverage, name suggestion, and template application, without breaking the template's remaining items.

#### Scenario: Item without exercise is skipped
- **WHEN** a template item's exercise is no longer available
- **THEN** the template still renders and applies its other items, and the missing item contributes nothing
