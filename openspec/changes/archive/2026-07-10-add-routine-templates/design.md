## Context

The app's daily loop is: pick exercises one by one on the logging screen (`ContentView`), accumulate `DraftSeries` in view state keyed by day, then "Finish Day" persists a `WorkoutSession` with ordered `WorkoutSeries`. The Routines tab (`RoutineListView`) is pure history. There is no planning concept: nothing stores "the workout I intend to do", so users rebuild the same push/pull/leg structures manually every day.

Relevant existing pieces this change builds on:

- `Exercise` (SwiftData, stable string id, localized name/content resolution, primary/secondary `Muscle` metadata).
- `WorkoutSeries.exercise` is an optional relationship — the codebase already tolerates a missing exercise; templates must do the same.
- `MuscleChips` view renders primary (emphasized) / secondary (muted) muscle labels — the established visual language for muscle metadata.
- `ExerciseHistoryProvider` provides pure-function summaries (last performed, best set) over fetched series.
- Full EN/ES localization is a standing requirement; user-entered text (template names) is stored verbatim, not localized.

## Goals / Non-Goals

**Goals:**

- Named, ordered, editable routine templates persisted locally in SwiftData.
- Per-exercise target set counts so a template describes structure ("bench ×4"), not just a list.
- Derived muscle-coverage summary on every template, reusing the exercise muscle metadata and `MuscleChips` presentation.
- One-tap "start day from template" on the logging screen that stages the plan without polluting saved data with empty series.
- "Save session as template" from history, closing the loop history → plan.
- Suggested template names derived from the dominant muscle profile.
- Templates remain accurate for the future AI-suggestion feature: they are pure structure (exercise refs + targets), so they can later be produced from an API response without redesign.

**Non-Goals:**

- No weekday scheduling, reminders, or calendar integration.
- No sharing/export of templates.
- No persistence of in-progress day plans across app termination (day drafts already live in view state only; the applied plan follows the same rule).
- No AI-suggested routines in this change (future backend; templates are deliberately shaped so an AI response can map onto them later).
- No editing of saved sessions (unchanged invariant).

## Decisions

### 1. Data model: `RoutineTemplate` → ordered `RoutineTemplateItem` → `Exercise` reference

```
RoutineTemplate                     RoutineTemplateItem
┌──────────────────────┐            ┌──────────────────────────┐
│ name: String         │ 1 ── * ─▶  │ order: Int (0-based)     │
│ createdAt: Date      │  cascade   │ targetSets: Int (1...10) │
│ items: [Item]        │            │ exercise: Exercise?      │
└──────────────────────┘            └──────────────────────────┘
```

- Mirrors the proven `WorkoutSession`/`WorkoutSeries` shape: cascade delete from template to items, `order` column with an `orderedItems` computed property, optional `exercise` reference tolerated everywhere (skipped in display and application), inverse relationship on the item side.
- **Alternative considered — storing `[exerciseID]` string arrays on the template:** simpler schema, but loses referential integrity, requires manual id→Exercise resolution in every view, and can't carry per-item attributes like `targetSets`. Rejected.
- `targetSets` is a required `Int` defaulting to 3 (stepper range 1–10). An optional was considered but adds nil-handling everywhere for no user value — "how many sets do you intend" always has an answer, and 3 is a sane default.
- Additive schema change only → SwiftData lightweight migration, consistent with how `Exercise.summary` was added.

### 2. Muscle coverage is derived, never stored

`RoutineTemplate` exposes `primaryMusclesCovered` / `secondaryMusclesCovered` computed properties: union of item exercises' primary muscles in first-appearance order (same idiom as `WorkoutSession.musclesWorked`); secondary coverage excludes muscles already covered as primary. Storing coverage would desync when an exercise's muscles are edited (exercise-editing capability exists). Derivation logic lives as pure static helpers so unit tests need no UI, matching `ExerciseHistoryProvider` style. Rendered with the existing `MuscleChips` view on template rows, detail, and the editor.

### 3. Name suggestion is a pure function over the muscle profile

`TemplateNameSuggester.suggestedName(for: [Exercise]) -> String?`:

- Tally primary muscles across the exercises (each exercise votes once per primary muscle).
- If a lower-body group (glutes/quads/hamstrings/calves) holds the majority → "Leg Day". If all exercises are cardio → "Cardio". Otherwise join the top one or two muscles' localized `displayName`s: "Chest & Triceps".
- Returns `nil` for an empty exercise list; the form then shows a plain empty name field.
- Suggestion is evaluated in the current locale at creation time and inserted as editable text — the stored name is always plain user content. It is a placeholder/offer, never applied silently over a user-typed name.
- **Alternative considered — localizing stored names via keys:** rejected; template names are user data, and locale-frozen suggestions are the honest behavior.

### 4. Applying a template stages a *plan*, it does not create draft series

`ContentView` gains a second piece of per-day view state alongside `drafts`: `plans: [Date: [PlannedExercise]]` where `PlannedExercise` is a value type (exercise, targetSets). Applying a template fills the selected day's plan. The plan renders as its own checklist section:

```
┌ Plan: Push Day ─────────────────────────┐
│ Bench Press          2/4 sets  Last: 60kg × 8 │  ← tap → SetEntrySheet
│ Incline DB Press     0/3 sets  Last: 22.5kg × 10 │
│ ⋯                                        │
└──────────────────────────────────────────┘
```

- Tapping a planned row opens the existing `SetEntrySheet` for that exercise; each saved set appends a normal `DraftSeries`, and the row's progress count (`logged/target`) is derived by counting the day's drafts for that exercise.
- "Last: …" reference values come from `ExerciseHistoryProvider.summary` (most recent session's last set for that exercise), formatted with `DraftSeries.summary`.
- "Finish Day" is unchanged: it persists only actual `DraftSeries`. Unmet targets are simply not saved — the plan is guidance, not data.
- **Alternative considered — materializing target sets as empty `DraftSeries`:** rejected; drafts represent performed sets, and empty ones would either corrupt saved sessions or need a parallel "pending" flag through the whole finish path.
- The plan is view-state only, exactly like drafts. If the app is killed mid-day the plan is lost with the drafts — an accepted, pre-existing trade-off kept consistent rather than half-fixed.
- Applying a template when the day already has a plan replaces it after confirmation; applying is unavailable on days with a saved session (those are read-only today).

### 5. Routines tab: two sections in one list, templates first

`RoutineListView` becomes two `List` sections — "Templates" (each row: name, exercise count, muscle chips; navigation to a template detail/editor; toolbar `+` to create) and "History" (existing rows unchanged). Templates are user-curated and few, so sections beat a segmented control (both worlds visible, no hidden mode); if either section is empty it shows a compact inline empty state instead of hijacking the whole screen.
**Alternative considered — a fifth root tab:** rejected; four tabs already exist and planning/reviewing routines belong together conceptually.

### 6. Save-session-as-template pre-fills the normal template editor

A toolbar action on `RoutineDetailView` builds template items from the session: exercises deduplicated in first-appearance order, `targetSets` = number of series that exercise had that day (clamped to 1–10), then presents the standard template editor sheet pre-filled, with the suggested name as placeholder. Nothing is persisted until the user saves — reusing the editor gives naming, reordering, and validation for free instead of a one-shot "silently created" template.

### 7. Editor form and validation

One `TemplateEditForm` used by create, edit, and save-from-session flows (mirrors `ExerciseEditForm` patterns): name field, ordered exercise rows with a per-row target-sets stepper, `EditButton`-driven reorder and swipe-to-delete, and an "Add Exercises" sheet with the library-style searchable exercise picker (case/diacritic-insensitive, localized names, multi-select). Save is disabled while the trimmed name is empty or the item list is empty. Duplicate (context menu on a template row) copies items and appends a localized "copy" suffix to the name; delete asks for confirmation.

## Risks / Trade-offs

- [Plan lost if the app terminates mid-workout] → Accepted for parity with existing drafts; both would be fixed together by a future "persistent in-progress day" change, and this design adds no new persistence semantics to unwind.
- [Template references a user-modified or future-deleted exercise] → Items hold optional references and skip nil exercises on display/application, mirroring `WorkoutSeries`; muscle coverage recomputes automatically after exercise edits.
- [Name suggestions feel wrong for mixed routines] → The suggestion is only ever a pre-filled, fully editable offer; worst case the user types their own name, which is the status quo.
- [Two sections crowd the Routines tab on small screens] → Template rows are single-line + chips; history remains one flick away. If template counts grow unexpectedly, a follow-up can collapse the section — not worth a mode switch now.
- [SwiftData schema addition] → Additive models only; verified by launching against a store created by the current build (same approach as previous model additions).

## Open Questions

- None blocking. The exact visual treatment of the plan section (card vs. plain section) can be settled in implementation within the existing list style.
