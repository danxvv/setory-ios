## Context

The main page is the Log tab (`Setory/Views/ContentView.swift`): a `NavigationStack` → `List` with a calendar header, a plan section, and a series section. The "current routine" is derived at display time and appears in one of three states:

- **Staged plan** (unsaved day with an applied template): `plans[selectedDate]` is a `DayPlan`; each `PlannedExercise` holds a concrete `Exercise` (`ContentView.swift:118-163`).
- **Draft series** (unsaved day, logging in progress): each `DraftSeries` exposes `.exercise` (`ContentView.swift:224-249`).
- **Saved session**: `savedSession.orderedSeries`; each `WorkoutSeries` has an optional `exercise` (`ContentView.swift:198-223`). Rows are rendered by `seriesRow(name:summary:index:)` (`ContentView.swift:276`), which today receives only the exercise *name*.

A complete media stack already exists and is used everywhere except the main page:

- `ExerciseThumbnailView(exercise: Exercise, size: CGFloat = 40)` — bundled thumbnail, synchronous/offline, category-icon fallback (`Setory/Views/ExerciseThumbnailView.swift`).
- `ExerciseMediaView(exercise: Exercise)` — 180×180 animated GIF with loading state, thumbnail degradation, retry, and the Gym visual attribution (`Setory/Views/ExerciseMediaView.swift`).
- `ExerciseMediaStore` (environment: `\.exerciseMediaStore`) — bundle thumbnails + pinned-CDN GIF download with permanent on-disk cache keyed by exercise `id`.
- Media gate: `exercise.hasMedia` (`gifFileName != nil`).

## Goals / Non-Goals

**Goals:**
- Show each exercise's thumbnail in all three routine-row states on the main page.
- Give the user a way to view the animated demonstration for any routine exercise with media, without leaving the logging flow.
- Reuse the existing media components and store unchanged; keep behavior offline-first.
- Preserve every existing row interaction (plan row → set-entry popup, saved row → `RoutineDetailView` navigation, swipe-to-delete on drafts).

**Non-Goals:**
- No inline/autoplaying GIFs in list rows (performance, distraction, network cost).
- No media in the calendar header, `RoutineDetailView`, or other screens (they have their own specs).
- No changes to the exercise catalog, media pipeline, CDN pinning, or SwiftData models.
- No changes to muscle-target metadata or the AI suggestion flow.

## Decisions

1. **Row thumbnails via `ExerciseThumbnailView`** (size 40, matching library rows). It is synchronous and bundle-backed, so it is safe inside `List` rows, and it already implements the category-icon fallback required for exercises without media. Alternative — inline `AnimatedGIFView` per row — rejected: decoding N GIFs in a list is expensive and visually noisy.

2. **Animated demonstration in a sheet, not a navigation push.** A new lightweight view (`RoutineMediaSheet`, new file in `Setory/Views/`) wraps the existing `ExerciseMediaView(exercise:)` in a `NavigationStack` with the exercise's localized name as title and a Done button. `ExerciseMediaView` already provides on-demand fetch, disk cache, thumbnail degradation with retry, and the attribution caption, so the sheet adds only chrome. Alternative — navigating to `ExerciseDetailView` — rejected: it pulls the user out of the logging context and drags in unrelated detail content.

3. **Thumbnail tap = borderless button inside the row.** Each thumbnail is wrapped in a `Button` with `.buttonStyle(.borderless)`, which is the SwiftUI-sanctioned way to have an independently tappable region inside a `List` row without hijacking the row's primary action (set-entry popup on plan rows, `NavigationLink` on saved rows). Alternative — `.onTapGesture` on the image — rejected: fights `List` selection and is worse for accessibility. The button is only attached when `exercise.hasMedia`; otherwise the thumbnail (fallback icon) is inert.

4. **Sheet presentation via `.sheet(item:)` with `@State private var mediaExercise: Exercise?`.** `Exercise` is a SwiftData `@Model` (hence `Identifiable`), so one optional drives the sheet for all three row types.

5. **`seriesRow` learns about the exercise.** `seriesRow(name:summary:index:)` changes to also receive the `Exercise?` (from `WorkoutSeries.exercise` / `DraftSeries.exercise`) so saved and draft rows can render the thumbnail. A `nil` exercise (deleted catalog entry) renders the category-agnostic fallback icon and no viewer affordance.

6. **Localization.** New strings (sheet Done button if not system-provided, accessibility labels such as "Show demonstration for %@") go into `Localizable.xcstrings` with `es` translations; `LocalizationTests` enforces completeness. Exercise names remain English-only per the localization spec.

## Risks / Trade-offs

- [Gesture conflict: thumbnail tap swallowed by row button / NavigationLink] → `.buttonStyle(.borderless)` scopes the hit area to the thumbnail; UI tests assert both the row action and the thumbnail action still work.
- [Saved series with a deleted exercise (`exercise == nil`)] → fallback icon, no tap affordance; row text behavior unchanged.
- [List scrolling cost of synchronous thumbnail loads] → thumbnails are small bundled JPEGs already loaded the same way in the library list; no measurable risk, no new caching layer needed.
- [Sheet + network flakiness in UI tests] → reuse the existing `isNetworkDisabled` store flag and `-uitest-reset` launch-argument conventions; offline tests assert thumbnail degradation instead of GIF playback.
- [Duplicate exercises in a routine open the same viewer] → acceptable; the GIF cache is keyed by exercise `id`, so repeat opens are served from disk.

## Migration Plan

UI-only change; no data migration. Rollback = revert the view changes and remove the new sheet file and localization keys.

## Open Questions

None blocking. Thumbnail size (40pt) and sheet detent (medium/large) are cosmetic choices finalized during implementation.
