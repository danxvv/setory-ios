## Why

Today the user rebuilds every workout from scratch: pick each exercise, one by one, every day — even though real training follows repeating structures (push day, leg day, upper/lower). The "Routines" tab only shows *history*; there is no way to plan or reuse a workout. Named, reusable routine templates close the planning gap, make logging dramatically faster, and give muscle-target metadata a second job: describing what a planned routine covers, not just what a finished session worked.

## What Changes

- New **routine templates**: named, ordered lists of exercises from the catalog, created and edited by the user.
  - Create a template by picking exercises (searchable, reusing the catalog), naming it, and optionally setting a target set count per exercise.
  - Edit everything later: rename, add/remove/reorder exercises, change target sets.
  - Delete and duplicate templates.
- **Muscle coverage summary**: every template displays the muscles it works, derived from its exercises' primary/secondary muscle metadata (primary emphasized, secondary muted — same visual language as the rest of the app).
- **Suggested template name**: when creating a template, the app proposes a name from the dominant muscle profile (e.g. "Chest & Triceps", "Leg Day"); the user can accept or type their own.
- **Start a day from a template**: on the logging screen, applying a template pre-stages its exercises (honoring target sets) so the user only fills in reps/weight/time instead of rebuilding the day. Each staged exercise shows the last-performed values as a reference.
- **Save a finished session as a template**: from a saved routine's detail view, one action turns that day's exercises into a new template.
- **Routines tab restructure**: the Routines tab now hosts two sections — Templates (new) and History (existing list) — so planning and reviewing live side by side.
- Full EN/ES localization of all new UI, per the existing localization requirements.

Out of scope: AI-suggested routines (future backend), scheduling templates to weekdays, template sharing/export.

## Capabilities

### New Capabilities
- `routine-templates`: creating, editing, duplicating, and deleting named routine templates; per-exercise target sets; derived muscle-coverage summary; suggested names; creating a template from a saved session.

### Modified Capabilities
- `workout-logging`: new requirement — the logging screen can apply a routine template to the selected day, pre-staging its exercises (with last-performance reference values) for set entry.
- `routine-history`: the Routines tab requirement changes from "lists saved sessions" to "hosts a Templates section and a History section"; the routine detail view gains a "save as template" action.

## Impact

- **Models**: new `RoutineTemplate` + `RoutineTemplateItem` SwiftData models (template → ordered items → `Exercise` references). Existing models untouched; `Exercise` deletion semantics must be considered (catalog exercises are never deleted today, but template items should tolerate a missing exercise like `WorkoutSeries` does).
- **Views**: new template list/detail/edit views; `RoutineListView` restructured into sections; `ContentView` (logging) gains the apply-template flow; `RoutineDetailView` gains save-as-template.
- **Services**: small additions — name suggestion from muscle profile; reuse of `ExerciseHistoryProvider` for last-performance prefill.
- **Localization**: new keys in `Localizable.xcstrings` with Spanish translations (existing completeness requirement applies).
- **Tests**: unit tests for template CRUD, muscle summary derivation, name suggestion, and apply-to-day staging; UI test for the create-and-apply happy path.
- No backend, no migration risk beyond additive SwiftData models (lightweight migration).
