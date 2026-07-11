## ADDED Requirements

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
