# Screens and user flows

[Documentation index](README.md)

## Log

Main source: [LogView.swift](../Setory/Features/Log/LogView.swift).

The screen owns the selected start-of-day date, drafts keyed by date, day plans keyed by date, and sheet state. It queries sessions, templates, and saved series. A matching saved session decides whether the selected day is editable.

| State | Visible behavior |
| --- | --- |
| Unsaved day without sets | Empty-state guidance, exercise entry, and template entry when templates exist |
| Unsaved day with plan | Plan checklist, logged/target counts, and previous saved-set references |
| Unsaved day with sets | Draft series list with deletion and a bottom Finish Day button |
| Saved day | Saved workout information and navigation to its read-only detail |

`MonthCalendarView` uses `MonthGrid` for month navigation, localized weekday order, leading blanks, and day cells. It marks today, the selected day, and days with saved workouts. Browsing another month does not itself select another date.

### Logging a set

1. Open `ExercisePickerSheet`, which shares search and filters with the library.
2. Select one exercise; Log waits for the picker to dismiss before showing `SetEntrySheet`.
3. For strength, enter positive integer repetitions and optionally a nonnegative weight in kilograms. Decimal commas in weight are converted to decimal points.
4. For cardio, enter positive integer minutes; the draft stores seconds.
5. Confirm appends one `DraftSeries` to the selected day. Cancel discards the entry.

Set confirmation does not write to the database. Draft rows can be removed before finishing. `Finish Day` requires at least one draft and no saved session for that date. It saves the ordered drafts, then clears that day's drafts and plan. The current UI does not reopen, edit, or delete a finished workout.

### Starting from a template

`TemplateApplyPicker` presents templates sorted by localized name. Applying one snapshots its name and stages its exercises with target counts. Repeated exercise IDs are merged and their target counts summed. Missing exercise references are skipped.

Each plan row counts all of the day's drafts for its exercise ID, including drafts logged before the template was applied. A row is complete at `logged >= target`; the target does not stop further logging. Its “Last” reference is the last ordered set from that exercise's most recent saved session, not necessarily its strongest set.

Replacing an existing plan asks for confirmation and preserves logged drafts. Unmet plan targets never create saved sets. Tapping a routine thumbnail opens the shared demonstration sheet independently of the row's log action.

## Exercises

Sources: [ExerciseLibraryView](../Setory/Features/Catalog/ExerciseLibraryView.swift), [FilteredExerciseList](../Setory/Features/Catalog/FilteredExerciseList.swift).

The catalog browser and both exercise pickers share a list shell. Search, an optional primary-muscle filter, and an optional equipment filter combine with AND semantics. Search matches the localized display name or canonical stored name and ignores case and diacritics. Results sort by localized name. No results produces an empty state while retaining search/filter controls.

`ExercisePickerSheet` returns a single exercise to Log. `ExerciseMultiPicker` keeps selected IDs until Add and returns selected exercises in localized-name order, rather than tap order. The template editor can reorder them afterward.

### Exercise detail

[ExerciseDetailView](../Setory/Features/Catalog/ExerciseDetailView.swift) resolves the routed ID and shows:

- Animation/thumbnail when media exists, category, equipment, and primary/secondary muscles.
- Description and ordered instructions when available.
- History: last performed date, best set, and up to five recent sessions; otherwise “Not performed yet.”
- A progression link when history exists.
- Up to six other exercises sharing at least one primary muscle, sorted by localized name.

An unresolved exercise ID shows an unavailable state. Edit swaps the detail content for `ExerciseEditForm`.

### Exercise editing

The editor starts from the text currently displayed in the user's language. It edits name, category, primary/secondary muscles, description, and instruction steps. It does not edit equipment or media identifiers.

Saving requires a nonblank trimmed name and at least one primary muscle. Normalization trims text, removes empty steps, orders muscles canonically, and removes primary muscles from the secondary selection. A normalized no-op exits without marking the record modified. An actual save sets `isUserModified`, preserving the user's text against later catalog updates and disabling translated display overrides for that record. Cancel discards the form values.

## Routines

[RoutineListView](../Setory/Features/Routines/RoutineListView.swift) has two independent sections:

| Section | Ordering and actions |
| --- | --- |
| Templates | Localized name order; tap to edit, create with toolbar, duplicate via context menu, delete with confirmation |
| History | Newest session date first; tap for completed-workout detail |

Template rows derive muscle coverage from current exercise references. Duplicate creates new template/item records with the localized “copy” suffix. Deleting a template cascades to its items and leaves workout history intact.

### Template editor

[TemplateEditForm](../Setory/Features/Routines/TemplateEditForm.swift) handles blank creation, editing, conversion from a session, and AI review. All edits accumulate in `TemplateDraft` until Save.

- Add exercises with the multi-picker or photo matching. New rows default to three sets.
- Change targets between 1 and 10, delete rows, and reorder them.
- Review derived primary and secondary muscle coverage.
- Save requires a nonblank trimmed name and at least one item.
- Name suggestions update only while the field is empty or still equals the previous automatic suggestion; typed names are preserved.
- An AI-generated draft also displays the rationale.

A session-derived draft combines sets for each exercise in first-appearance order and clamps their counts to 1–10. It creates a reusable plan, not a copy of weights, repetitions, or durations.

### Saved workout detail

[RoutineDetailView](../Setory/Features/Routines/RoutineDetailView.swift) shows the workout date, deduplicated primary muscles, and saved series in recorded order. “Save as template” opens the standard editor with a prefilled draft. Nothing new is saved until the user saves that editor.

## Progress

[ProgressTabView](../Setory/Features/Progress/ProgressTabView.swift) shows an empty state until a session exists. Otherwise it presents an eight-week workout chart, week/month workout and series totals, muscle balance for the selected week or month, and a searchable list of performed exercises.

Entering search text hides overview and balance sections to focus on exercises. Unperformed catalog exercises are excluded. Selecting an exercise opens [ExerciseProgressionView](../Setory/Features/Progress/ExerciseProgressionView.swift), which presents the relevant metric, personal records, and weighted volume where applicable. See [exact calculation rules](data-and-statistics.md).

## AI and settings

“Suggest with AI” in Routines opens a goal-entry sheet with Generate, progress/cancel, and error recovery states. A successful response opens the template editor for review; it does not save automatically.

“Match from Photo” inside the template editor accepts up to three camera/library images plus optional description and primary-muscle hints. Results start with no selection. Add appends the chosen local exercises to the current template draft. Returning to capture retains the photos and hints. See [AI integration](ai.md) for all request and validation rules.

`AISettingsView` is available from Routines and AI recovery flows. Save Key stores a trimmed nonempty key and clears the entry field; Clear Key removes it. Existing keys are never filled back into the field. The model override is immediately bound to app preferences; Done dismisses the sheet. About & Licenses opens `AboutView`, which displays dataset and media attribution.
