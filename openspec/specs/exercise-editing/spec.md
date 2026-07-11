# exercise-editing Specification

## Purpose
Allow the user to edit an exercise from its detail screen via an in-place, pre-filled form — changing name, category, muscles, description, and instruction steps with validation — where saving marks the exercise as user-modified so its stored values display verbatim everywhere and survive catalog reseeding, and cancel discards all unsaved changes.

## Requirements

### Requirement: Edit mode on the detail screen
The exercise detail screen SHALL provide an Edit action that switches the screen into an edit form in place. The form MUST be pre-filled with the values currently displayed (the localized/resolved name, description, and instruction steps, plus category and muscle metadata), so what the user sees is what they edit.

#### Scenario: Entering edit mode
- **WHEN** the user taps Edit on the detail screen for `bench-press` on a Spanish device
- **THEN** the screen becomes an edit form pre-filled with the Spanish name, Spanish description, Spanish instruction steps, the strength category, and the current primary/secondary muscles

### Requirement: Editable fields and validation
The edit form SHALL allow changing the exercise's name, category, primary muscles, secondary muscles, description, and instruction steps (adding, removing, editing, and reordering steps). Saving MUST be rejected while the name is empty or while fewer than one primary muscle is selected; the exercise's stable `id` MUST NOT be editable.

#### Scenario: Saving edits persists them
- **WHEN** the user changes the description and adds an instruction step, then taps Save
- **THEN** the detail screen shows the updated content, and the changes are still present after relaunching the app

#### Scenario: Empty name is rejected
- **WHEN** the user clears the name field and attempts to save
- **THEN** the save is blocked and the form indicates the name is required

#### Scenario: Muscle metadata cannot be removed entirely
- **WHEN** the user deselects all primary muscles and attempts to save
- **THEN** the save is blocked and the form indicates at least one primary muscle is required

### Requirement: Cancel discards changes
The edit form SHALL provide a Cancel action that discards all unsaved modifications and returns to the read-only detail screen.

#### Scenario: Cancel leaves the exercise unchanged
- **WHEN** the user edits several fields and taps Cancel
- **THEN** the detail screen shows the exercise exactly as before edit mode was entered

### Requirement: Edited exercises display stored values
Saving an edit SHALL mark the exercise as user-modified. A user-modified exercise MUST display its stored name, description, and instruction steps verbatim everywhere in the app (library list, detail screen, pickers, workout rows, routine summaries) — the catalog localization tables no longer apply to it. Its `id`, and the raw serialization of its category and muscle values, MUST remain locale-independent.

#### Scenario: Renamed exercise keeps the user's name
- **WHEN** the user renames `bench-press` to "Press banca plano" and saves
- **THEN** every screen shows "Press banca plano" regardless of device language, including after relaunch

#### Scenario: Edits survive catalog reseeding
- **WHEN** the app relaunches and the catalog seeder runs after an exercise was user-modified
- **THEN** the seeder leaves the user-modified exercise untouched while still backfilling unmodified exercises
