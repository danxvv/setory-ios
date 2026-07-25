# exercise-media Specification (Delta)

## ADDED Requirements

### Requirement: Bundled exercise thumbnails
Every catalog exercise SHALL have a thumbnail image (180×180) shipped in the app bundle and resolvable by the exercise's stable `id`. Thumbnails MUST display without network connectivity. An exercise without a media reference (e.g. a user-space exercise preserved from the legacy catalog) MUST fall back to its category icon wherever a thumbnail would appear, with no broken-image placeholder.

#### Scenario: Thumbnails available offline
- **WHEN** the user browses the exercise library in airplane mode
- **THEN** every catalog exercise row shows its thumbnail image loaded from the app bundle

#### Scenario: Exercise without media falls back to category icon
- **WHEN** an exercise with no media reference is displayed in a list or picker row
- **THEN** its category icon (strength or cardio) is shown in place of a thumbnail

### Requirement: On-demand animated demonstrations
The exercise detail screen SHALL display an animated demonstration (GIF) for exercises that have a media reference. The animation MUST be fetched on demand from a CDN URL pinned to a fixed dataset commit, stored in a persistent on-disk cache keyed by exercise `id`, and served from that cache on every subsequent view without a network request. Animation playback MUST NOT require any third-party dependency.

#### Scenario: First view downloads and plays
- **WHEN** the user opens the detail screen of a catalog exercise for the first time with network connectivity
- **THEN** the animated demonstration downloads, plays in the media section, and is written to the on-disk cache

#### Scenario: Subsequent views are offline
- **WHEN** the user re-opens the same detail screen in airplane mode
- **THEN** the animated demonstration plays from the cache with no network request

### Requirement: Graceful media degradation
When an animated demonstration is not cached and cannot be fetched (offline, server error, or missing asset), the detail screen SHALL show the exercise's bundled thumbnail in its place with a non-blocking retry affordance. Media failures MUST NOT produce error alerts and MUST NOT affect any non-media functionality.

#### Scenario: Offline first view degrades to thumbnail
- **WHEN** the user opens a detail screen in airplane mode and the animation is not cached
- **THEN** the media section shows the bundled thumbnail and a retry affordance, and no error alert appears

#### Scenario: Retry after connectivity returns
- **WHEN** the user activates the retry affordance once connectivity is restored
- **THEN** the animation downloads, plays, and is cached

### Requirement: Media attribution
The app SHALL display the attribution string "© Gym visual — https://gymvisual.com/" in the exercise detail media section, and SHALL provide an About/licenses surface containing the dataset's MIT license and media notice text. Attribution MUST ship in every build that includes the media.

#### Scenario: Attribution alongside media
- **WHEN** the detail screen's media section is displayed (animation or thumbnail fallback)
- **THEN** the Gym visual attribution string is visible in that section

#### Scenario: Licenses in About surface
- **WHEN** the user opens the About/licenses surface from settings
- **THEN** the MIT license and the Gym visual media notice are readable
