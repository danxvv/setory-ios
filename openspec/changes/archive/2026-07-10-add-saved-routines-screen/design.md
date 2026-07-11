# Design — Add Saved Routines Screen

## Context

The app currently has a single screen (`ContentView`): a month calendar plus the selected day's series list, backed by SwiftData (`WorkoutSession` → ordered `WorkoutSeries` → `Exercise`). Selecting a saved day already shows that day's series inline, but there is no way to browse all saved routines or to open a dedicated, fuller view of one session. All data needed for this feature already exists in the store; this is a read-only presentation change.

## Goals / Non-Goals

**Goals:**
- A "Routines" screen listing every saved session, newest first.
- A routine detail view for one session, reachable from both the list and the logging screen's calendar.
- Keep the existing logging flow untouched apart from the new navigation entry point.

**Non-Goals:**
- Editing or deleting saved sessions (saved days remain immutable, per `workout-logging`).
- Naming/renaming routines, reusing a routine as a template for a new day.
- AI suggestions or any backend interaction.
- Statistics/aggregations beyond a simple per-session summary.

## Decisions

### 1. Root becomes a `TabView` with "Log" and "Routines" tabs

The new screen is a peer of the logging screen, not a sub-screen of it. A tab bar is the standard iOS pattern for two top-level destinations and leaves room for a future "Suggestions" tab.

- *Alternative considered*: a toolbar button on the logging screen pushing the list. Rejected — hides the history behind the logging flow and couples two unrelated screens' navigation stacks.
- `gymappApp` keeps owning the `ModelContainer`; the new `RootTabView` (or inline `TabView` in the `WindowGroup`) wraps `ContentView` and `RoutineListView`. Each tab owns its own `NavigationStack`.

### 2. Plain SwiftData `@Query`, no view model

`RoutineListView` uses `@Query(sort: \WorkoutSession.date, order: .reverse)`. The feature is read-only over existing models; introducing an `@Observable` store would add indirection with no shared state to justify it. This matches the existing codebase style (`ContentView` uses `@Query` directly).

### 3. `RoutineDetailView` takes a `WorkoutSession` and is shared by both entry points

One detail view, two `NavigationLink` sources: list rows on the Routines tab, and the saved-workout section on the Log tab. It renders `session.orderedSeries` reusing the existing row pattern and `DraftSeries.summary(...)` for value formatting, and additionally surfaces each exercise's primary-muscle metadata (chips/subtitle) plus a "muscles worked" summary for the session — muscle targets are core domain data and this is where the user reviews a session.

### 4. Calendar navigation = link from the saved-workout section, not a second tap gesture

Tapping a calendar day keeps its single existing meaning: select the day. When the selected day has a saved session, the inline "Saved workout" section becomes/offers a `NavigationLink` into `RoutineDetailView`. This satisfies "tap a day to see its routines" without overloading the day cell with select-vs-navigate ambiguity.

- *Alternative considered*: navigating directly on day tap. Rejected — it would break the existing select-to-log interaction for unsaved days and make month browsing jarring.

## Risks / Trade-offs

- [Sessions list grows unbounded over years] → `@Query` with `List` is lazy; acceptable for a personal log. No pagination needed now.
- [`WorkoutSeries.exercise` is optional; a deleted/missing exercise would leave gaps in detail rows] → detail view falls back to a placeholder name (same pattern `ContentView` already uses) and omits muscle chips when no exercise is attached.
- [Two entry points to the same detail view could drift visually] → single `RoutineDetailView` component, no per-entry-point variants.

## Open Questions

None — scope is intentionally small and read-only.
