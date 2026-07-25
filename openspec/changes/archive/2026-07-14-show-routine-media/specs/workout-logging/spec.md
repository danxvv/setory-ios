## ADDED Requirements

### Requirement: Routine media on the logging screen
Every routine row on the logging screen — planned exercise rows, unsaved draft series rows, and saved-session series rows — SHALL show the exercise's bundled thumbnail, falling back to the exercise's category icon when the exercise has no media reference, and to a neutral placeholder icon when the row's exercise is missing (e.g. deleted). For exercises with a media reference, the thumbnail SHALL act as an affordance that opens a media viewer presenting that exercise's animated demonstration with the exercise's localized name, per the `exercise-media` capability (on-demand fetch, on-disk cache, thumbnail degradation with retry, and attribution). Opening the viewer MUST NOT trigger the row's primary action (set-entry popup or routine-detail navigation), and all existing row interactions (row tap, swipe-to-delete) MUST continue to work. Exercises without a media reference MUST NOT offer the viewer affordance. This requirement changes presentation only: it MUST NOT alter what is logged or saved, nor the exercises' muscle-target metadata.

#### Scenario: Plan rows show thumbnails
- **WHEN** the user applies a routine template to an empty day
- **THEN** each planned exercise row shows the exercise's thumbnail (or category-icon fallback) alongside its name, progress, and reference values

#### Scenario: Series rows show thumbnails
- **WHEN** the selected day has draft series or a saved session
- **THEN** each series row shows the exercise's thumbnail (or category-icon fallback) alongside its name and recorded values

#### Scenario: Thumbnail opens the animated demonstration
- **WHEN** the user taps the thumbnail of a routine exercise that has a media reference
- **THEN** a media viewer opens showing that exercise's animated demonstration and name, and the row's primary action is not triggered

#### Scenario: Row actions keep working alongside media
- **WHEN** the user taps a planned exercise row outside its thumbnail
- **THEN** the set-entry popup opens as before, and no media viewer appears

#### Scenario: Exercise without media offers no viewer
- **WHEN** a routine row's exercise has no media reference
- **THEN** the row shows the category icon in place of a thumbnail and tapping it does not open the media viewer

#### Scenario: Saved series with a missing exercise
- **WHEN** a saved-session series row's exercise no longer exists
- **THEN** the row shows a placeholder icon, offers no viewer affordance, and its name and values render as before
