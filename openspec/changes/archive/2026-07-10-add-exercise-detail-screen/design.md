# Design — add-exercise-detail-screen

## Context

The app is SwiftUI + SwiftData (iOS 17+), local-only. The exercise catalog (40 exercises) is seeded once from `Resources/exercises.json` by `CatalogSeeder`; each `Exercise` stores a stable `id`, canonical English `name`, `category` (strength/cardio), and primary/secondary muscle raws. Display names are resolved at render time from the `ExerciseNames` string catalog keyed by `exercise.<id>`, falling back to the stored name. Exercises appear only in the Log tab's "Add Exercise" menu and in workout rows — there is no browse or detail UI, and the catalog has no description or instructions content.

The catalog will eventually come from a REST API (same backend project that serves AI suggestions); today everything must work offline from bundled data.

## Goals / Non-Goals

**Goals:**
- A third root tab ("Exercises") to browse and search the catalog.
- A detail screen per exercise: category/muscle icons, localized description, step-by-step instructions, muscle-target visualization (primary vs secondary), personal history and PRs from local workout data, and related exercises by shared primary muscle.
- Full in-place editing of any exercise (name, category, muscles, description, instructions), persisted locally.
- Catalog content flows through a data-source abstraction so a future REST source can replace the bundled JSON without touching the UI.

**Non-Goals:**
- No networking or REST implementation now (only the seam and DTO shape).
- No custom-exercise creation (separate future change; `isCustom` stays reserved).
- No images, video, or anatomical body diagram — muscle visualization uses styled chips.
- No equipment/difficulty metadata (explicitly declined).
- No changes to workout logging or AI-suggestion behavior.

## Decisions

### D1: Store description/instructions on the `Exercise` model, localized via a string-catalog table
New stored properties: `summary: String` (the description) and `instructionSteps: [String]`, seeded from JSON with English canonical text — mirroring how `name` works today. Localized display resolves from a new `ExerciseContent` string catalog table keyed by `exercise.<id>.summary` and `exercise.<id>.step.<n>`, falling back to stored values.

- Why not resolve from JSON at render time only: edits must persist per-exercise, and SwiftData is already the store of record for exercises.
- Why a separate `ExerciseContent` table instead of growing `ExerciseNames`: names are short labels reused across pickers; content is long-form text. Separate tables keep audits (completeness tests) simple and keep the future REST-content migration isolated.
- Naming: the property is `summary`, not `description`, to avoid colliding with Swift's `CustomStringConvertible` convention on a class type.

### D2: One `isUserModified` flag; editing captures resolved values and freezes localization
On entering edit mode the form is pre-filled with the currently displayed (localized) values. On save, all fields are written to the store and `isUserModified = true`; from then on, name/summary/steps render from stored values only — the catalog string tables no longer apply.

- Why not per-field override flags: editing the description on a Spanish device must not silently flip the name back to English. Capturing the resolved values at edit time keeps what the user saw stable, with a single, predictable rule: "once you edit an exercise, you own its text."
- Trade-off: an edited exercise stops switching language with the device locale. Accepted — the user's text has no translations anyway.
- The AI-suggestion contract is unaffected: it keys on exercise `id` and muscle raw values, which remain stable (ids are never editable).

### D3: `ExerciseCatalogSource` protocol as the REST seam
A `CatalogExercise` Codable DTO (id, name, category, primaryMuscles, secondaryMuscles, summary, instructions) and a protocol `ExerciseCatalogSource { func loadCatalog() throws -> [CatalogExercise] }`. `BundledCatalogSource` decodes `exercises.json`; `CatalogSeeder` depends on the protocol. The future REST source returns the same DTO array from `GET /exercises`, so swapping sources is a one-line injection change.

- Why not build the remote source now: no backend exists; the rule is to develop against the contract with the bundled source acting as the stub.

### D4: Seeder backfill for upgraded installs
Existing stores already contain exercises without the new fields. SwiftData lightweight migration handles the schema (new properties get default values: `""`, `[]`, `false`). `CatalogSeeder` gains a backfill pass: for every already-seeded exercise with `isUserModified == false`, copy `summary`/`instructionSteps` (and any drifted catalog fields) from the DTO. User-modified exercises are never touched by seeding. The pass stays idempotent — running it twice changes nothing.

### D5: History aggregation as pure functions over fetched series
`ExerciseHistoryProvider` fetches this exercise's `WorkoutSeries` (via its sessions) and computes: last-performed date, best set — strength: heaviest `weightKg` (ties broken by reps), falling back to most reps when no set has weight; cardio: longest `durationSeconds` — and the most recent 5 sessions with per-session set summaries. Aggregation is pure `[WorkoutSeries] -> Summary` logic so unit tests need no UI.

### D6: UI structure
- `ExerciseLibraryView`: new `Tab("Exercises", systemImage: "figure.strengthtraining.traditional")` in `RootTabView` with its own `NavigationStack`; flat alphabetical list (reusing the catalog's locale-aware sort), `.searchable` filtering on localized name (case/diacritic-insensitive), rows show name + category icon + primary-muscle chips.
- `ExerciseDetailView`: sections — header (name, category icon: `dumbbell` for strength, `figure.run` for cardio), muscle chips (primary: filled accent capsules; secondary: muted outlined capsules; localized names), description, numbered instruction steps, history (or "never performed" empty state), related exercises (horizontal cards, same primary muscle, excluding self, alphabetical, capped at 6; section hidden when empty). Related cards push further detail screens on the same stack.
- Edit mode: toolbar Edit button switches the screen to a `Form` (TextField name, category Picker, muscle multi-select respecting "≥1 primary muscle", TextEditor summary, add/remove/reorder instruction steps) with Save/Cancel. Save validates then persists per D2; Cancel discards.

## Risks / Trade-offs

- [SwiftData migration on existing installs] → new properties carry default values so lightweight migration applies; seeder backfill (D4) fills real content on next launch. Verified by a unit test seeding an old-shape store.
- [Content authoring is the bulk of the work: 40 exercises × (summary + ~3–5 steps) × 2 languages] → author in batches by muscle group; a completeness unit test (like the existing localization audits) fails if any catalog id lacks `summary`, steps, or a Spanish entry.
- [Edited exercises stop localizing] → accepted per D2; the edit form warns nothing — behavior is deterministic and reversible only by re-editing. Documented in the spec.
- [Recursive navigation depth via related exercises] → value-based `navigationDestination(for:)` on the exercise id keeps the stack lightweight; no cycle risk beyond user-driven depth.
- [Search diacritics: "Press de banca" must match "banca" and "bánca"] → compare with `.localizedStandardContains`, which folds case and diacritics.

## Migration Plan

1. Ship model changes with defaulted properties (lightweight migration) + seeder backfill — safe for both fresh installs and upgrades.
2. UI lands behind nothing (no flag): the new tab is additive; existing tabs untouched.
3. Rollback = removing the tab; stored `summary`/`instructionSteps`/`isUserModified` fields are inert if unused.

## Open Questions

None blocking. Content tone/length for the 40 seeded exercises (kept to 1–2 sentence summaries and 3–5 steps) can be tuned during implementation review.
