## Context

This is the first feature change. The Xcode project already exists as a fresh SwiftUI + SwiftData template: single target `gymapp` (no test target yet), with the template's placeholder `Item` model, boilerplate `ContentView`, and a `ModelContainer` in `gymappApp.swift` currently registering `Item.self`. This change replaces that scaffolding and delivers the daily workout logging screen: calendar header, exercise dropdown, set-entry popup, series list, and a "Finish Day" save action. Everything is offline and local-only; the AI suggestion backend is a later, separate change. Muscle-target metadata must be modeled from day one because the future AI contract depends on it.

## Goals / Non-Goals

**Goals:**
- Restructure the existing `gymapp` target into a clean layout the rest of the app can grow into, removing the template scaffolding.
- SwiftData models for Exercise, WorkoutSession, and WorkoutSeries, including muscle-target metadata.
- Seed a bundled exercise catalog from a JSON resource, idempotently.
- Implement the logging screen per the `workout-logging` spec with a polished, native look.

**Non-Goals:**
- AI suggestions, the REST contract, or any networking.
- Custom user-created exercises (later change; the model should not preclude it).
- Editing an already-finished day, routine naming/reuse UX, statistics.
- iCloud sync or accounts.

## Decisions

- **Project layout**: keep the existing single app target `gymapp`; add folder groups `Models/`, `Views/`, `Services/`, `Resources/` inside it. Delete `Item.swift`, rewrite `ContentView.swift` as the logging screen, and update the `ModelContainer` schema in `gymappApp.swift` to register the new models. Plain MV pattern (SwiftUI views + `@Query`/`@Environment(\.modelContext)`); no ViewModel layer — the screen's state is simple enough that MVVM would add indirection without benefit at this size.
- **SwiftData models**:
  - `Exercise`: `id` (stable string from seed data), `name`, `category` (enum `strength`/`cardio` stored as raw string), `primaryMuscles: [String]`, `secondaryMuscles: [String]`, `isCustom: Bool` (false for seeded; reserved for the future custom-exercise change).
  - `WorkoutSession`: `date` (normalized to start-of-day, unique per day), `finishedAt`, ordered relationship to series.
  - `WorkoutSeries`: `order: Int`, reference to `Exercise`, `reps: Int?`, `weightKg: Double?`, `durationSeconds: Int?`. One flexible series type with optionals rather than two subtypes — SwiftData handles a single model more simply, and the exercise's category disambiguates which fields are meaningful.
  - Muscles as string raw values of a Swift `Muscle` enum (e.g., `chest`, `triceps`) rather than a separate SwiftData entity — the catalog is static, and strings serialize directly into the future AI API payload.
- **Catalog seeding**: `exercises.json` bundled in `Resources/`, loaded by a `CatalogSeeder` service on app launch; idempotency by checking existing seeded exercise ids before inserting. Seed ~30 common exercises covering major muscle groups plus a handful of cardio entries.
- **Calendar**: custom SwiftUI month grid (LazyVGrid) rather than `UICalendarView` — we need lightweight per-day decoration (saved-workout dot, selection ring) and month paging; a custom grid is less code than bridging UIKit and gives full styling control for the "well designed" requirement.
- **Unsaved-day state**: series added before "Finish Day" live in in-memory screen state (`@State` array of value-type drafts), not in SwiftData. Only "Finish Day" writes to the store, in one transaction creating the `WorkoutSession` and its `WorkoutSeries`. This makes cancel/remove trivial and matches the spec's "unsaved series" semantics. Trade-off: drafts are lost if the app is killed mid-logging (accepted for v1).
- **Set-entry popup**: `.sheet` with a compact detent (`.presentationDetents([.medium])`) containing the exercise name, category-appropriate inputs, and Confirm/Cancel. Sheets are the native iOS pattern for focused data entry; a custom overlay popup would fight the keyboard.
- **Viewing a saved day**: selecting a highlighted day shows its persisted series read-only (no "Finish Day" button). Editing saved days is out of scope.

## Risks / Trade-offs

- [Drafts lost on app termination before "Finish Day"] → Accepted for v1; a later change can stage drafts in SwiftData if it proves annoying.
- [Muscle names as free strings could drift from the future API contract] → Centralize in one `Muscle` enum; the AI-contract change must reuse it.
- [Custom calendar has date-math edge cases (month boundaries, first weekday, time zones)] → Normalize all dates with `Calendar.current.startOfDay`, drive the grid from `DateComponents`, and cover date logic with unit tests.
- [No test target exists in the template project] → Add a unit-test target as part of the restructuring tasks so date-math and seeding tests have a home.
- [Deleting the template `Item` model changes the SwiftData schema] → No real data exists yet (fresh template), so no migration is needed; delete the old store if a dev install complains.

## Open Questions

- None blocking. Weight unit is fixed to kg for v1; localization/imperial units can come later.
