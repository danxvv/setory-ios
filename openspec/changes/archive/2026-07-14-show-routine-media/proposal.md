## Why

The main page (the Log tab, `ContentView`) presents the day's routine as text-only rows — exercise names, set counts, and recorded values — while the rest of the app (library, pickers, detail screen) already shows exercise media. Users planning or logging a workout on the main page cannot see what an exercise looks like without navigating away, which is exactly when a visual reminder of the movement matters most.

## What Changes

- Show each exercise's bundled thumbnail (with the existing category-icon fallback) in every routine row on the main page: staged plan rows, in-progress draft series rows, and saved-session series rows.
- Add a tap affordance on those thumbnails that opens a media viewer sheet playing the exercise's animated demonstration (GIF), reusing the existing fetch-on-demand + on-disk cache + thumbnail-degradation + attribution behavior from the exercise detail screen.
- The thumbnail tap must not interfere with existing row interactions (plan row → set-entry popup, saved row → routine detail navigation, swipe-to-delete on drafts).
- New user-facing strings (viewer title/accessibility labels) are localized in English and Spanish.
- No data model or persistence changes; exercises without media keep working with the icon fallback and no viewer affordance.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `workout-logging`: the logging screen's routine rows (plan, draft series, saved series) gain exercise thumbnails and a way to open the animated demonstration for each exercise — added as a new requirement; existing row-content requirements are unchanged.
- `exercise-media`: the on-demand animated demonstration, graceful degradation, and attribution requirements are generalized from "the exercise detail screen" to any demonstration surface, now including the logging screen's media viewer.

## Impact

- **Views**: `gymapp/Views/ContentView.swift` (plan rows, draft rows, saved-session rows; `seriesRow` must receive the `Exercise`, not just its name); a new small media viewer sheet view that wraps the existing `ExerciseMediaView`.
- **Reused as-is**: `ExerciseThumbnailView`, `ExerciseMediaView`, `AnimatedGIFView`, `ExerciseMediaStore` (no service/API changes; media stays offline-first with the pinned CDN for GIFs).
- **Localization**: new keys in `gymapp/Localizable.xcstrings` with `es` translations (`LocalizationTests` audits completeness).
- **Tests**: UI tests for thumbnail presence and viewer opening on the logging screen; existing workout-logging UI tests may need row-accessibility updates.
- **No changes** to SwiftData models, the exercise catalog, or the AI suggestion flow.
