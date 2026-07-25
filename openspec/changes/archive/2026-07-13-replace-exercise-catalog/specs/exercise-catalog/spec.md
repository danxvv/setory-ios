# exercise-catalog Specification (Delta)

## MODIFIED Requirements

### Requirement: Bundled exercise catalog
The app SHALL ship with a bundled catalog of predefined exercises derived from the Gym visual dataset (pinned to a fixed dataset commit at transform time). Each exercise MUST have a unique identifier (`gv`-prefixed dataset id), a display name (canonical English), a category (`strength` or `cardio`), muscle-target metadata consisting of at least one primary muscle and zero or more secondary muscles expressed in the app's `Muscle` vocabulary, an equipment value, and a media reference resolving to its bundled thumbnail and remote animation. Exercises without muscle-target metadata MUST NOT exist in the catalog.

#### Scenario: Catalog is available on first launch
- **WHEN** the app launches for the first time
- **THEN** the full dataset-derived catalog is seeded into the local store and every exercise exposes its name, category, primary muscles, secondary muscles, equipment, and media reference

#### Scenario: Seeding is idempotent
- **WHEN** the app launches and the catalog has already been seeded
- **THEN** no duplicate exercises are created

#### Scenario: Dataset taxonomy is mapped to the app vocabulary
- **WHEN** a seeded exercise originating from a dataset record with a target outside the app's muscle vocabulary (e.g. "pectorals") is read from the store
- **THEN** its muscle-target metadata contains only valid `Muscle` raw values (e.g. `chest`)

### Requirement: Catalog query for selection UI
The app SHALL expose the catalog sorted alphabetically by display name, using locale-aware comparison for the current device language, for display in selection controls.

#### Scenario: Exercise list for selection
- **WHEN** the logging screen requests the exercise list
- **THEN** all catalog exercises are returned sorted alphabetically by display name under the current locale's comparison rules

### Requirement: Exercise descriptions and instructions
Every exercise in the bundled catalog SHALL include a description and at least one step-by-step instruction. The canonical (English) description and instruction steps are stored with the exercise, alongside per-locale variants imported from the dataset for supported languages (Spanish). At display time, content MUST resolve in this order: stored values verbatim for user-modified exercises; the per-locale variant for the current device language when present; the canonical English values otherwise. Muscle-target metadata, category, equipment, and `id` remain locale-independent serialization values.

#### Scenario: Seeded exercises carry content
- **WHEN** the catalog is seeded on first launch
- **THEN** every exercise exposes a non-empty description and a non-empty ordered list of instruction steps

#### Scenario: Spanish device resolves per-locale content
- **WHEN** a catalog exercise's description and instructions are displayed on a Spanish device
- **THEN** the Spanish variants stored with the exercise are shown, falling back to English where a Spanish variant is absent

#### Scenario: Backfill preserves user edits
- **WHEN** the seeder runs and an exercise is marked user-modified
- **THEN** that exercise's content fields are left untouched

### Requirement: Swappable catalog content source
The catalog SHALL be loaded through a data-source abstraction that yields exercise entries (id, name, category, primary muscles, secondary muscles, equipment, media reference, description and instruction steps with per-locale variants). The current implementation reads the bundled transformed JSON; the abstraction's entry shape defines the payload contract a future REST catalog endpoint must return, so replacing the source must not require UI or seeding-logic changes.

#### Scenario: Seeding consumes the abstraction
- **WHEN** the catalog seeder runs
- **THEN** it obtains all exercise entries, including equipment, media references, and per-locale content, exclusively through the catalog source abstraction backed by the bundled JSON

## ADDED Requirements

### Requirement: Equipment metadata
Every catalog exercise SHALL carry an equipment value from the dataset's fixed equipment vocabulary, stored as a locale-independent raw string. Equipment display names MUST be localized (English and Spanish) at render time.

#### Scenario: Equipment stored and displayed
- **WHEN** a barbell exercise is displayed on a Spanish device
- **THEN** the stored equipment raw value is unchanged (e.g. `barbell`) and the displayed label is Spanish (e.g. "Barra")

### Requirement: Version-gated seeding
Catalog seeding and alignment SHALL be gated by a bundled catalog version stamp: the bundled catalog JSON is parsed only when the stored version differs from the bundled version, and the stored version is updated after a successful seed. First launch counts as a version change.

#### Scenario: Unchanged version skips parsing
- **WHEN** the app launches and the stored catalog version equals the bundled catalog version
- **THEN** the bundled catalog JSON is not parsed and no seeding work occurs

#### Scenario: Version bump triggers reseed
- **WHEN** the app launches with a bundled catalog version newer than the stored one
- **THEN** the catalog is seeded/aligned idempotently and the stored version is updated

### Requirement: Legacy catalog migration
On first launch after the catalog replacement, before seeding, the app SHALL migrate exercises from the legacy 40-exercise catalog using a bundled legacy-id mapping: each legacy exercise whose id has a dataset equivalent MUST have its id rewritten in place to the dataset id, preserving all workout-series and template-item references. Legacy exercises without a dataset equivalent MUST be kept as user-space (custom) exercises when referenced by any workout series or template item, and deleted otherwise. The migration MUST be idempotent and MUST run at most once per store.

#### Scenario: Mapped legacy exercise keeps its history
- **WHEN** a store contains legacy exercise `bench-press` with logged series and the migration runs
- **THEN** the same exercise row's id becomes the mapped dataset id, all its logged series still reference it, and no duplicate bench-press exercise is created by the subsequent seed

#### Scenario: Unmapped legacy exercise with history is preserved
- **WHEN** a store contains a legacy exercise with no dataset equivalent (e.g. `face-pull`) that is referenced by a logged series
- **THEN** the exercise is kept, marked as a user-space exercise, and its logged series remain intact

#### Scenario: Unmapped legacy exercise without references is removed
- **WHEN** a store contains an unmapped legacy exercise referenced by no series and no template item
- **THEN** the exercise is deleted during migration

#### Scenario: Migration does not repeat
- **WHEN** the app launches again after a completed migration
- **THEN** no migration work is performed

## REMOVED Requirements

### Requirement: Localized exercise display names
**Reason**: The dataset provides no translated exercise names; display names are now the stored canonical English name for all exercises (user-modified exercises already displayed their stored name verbatim). The id-keyed exercise-name string catalog is deleted.
**Migration**: `localizedName` returns the stored `name`; `ExerciseNames.xcstrings` is removed from the project. Spanish content localization continues via per-locale stored descriptions and instructions (see "Exercise descriptions and instructions").
