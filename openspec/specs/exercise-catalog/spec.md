# exercise-catalog Specification

## Purpose
Provide a bundled catalog of predefined exercises, with category and muscle-target metadata, that the app seeds into local storage and exposes to selection UIs.

## Requirements

### Requirement: Bundled exercise catalog
The app SHALL ship with a bundled catalog of predefined exercises derived from the Gym visual dataset (pinned to a fixed dataset commit at transform time). Each exercise MUST have a unique identifier (`gv`-prefixed dataset id), a canonical English display name together with per-locale name variants for the supported languages, a category (`strength` or `cardio`), muscle-target metadata consisting of at least one primary muscle and zero or more secondary muscles expressed in the app's `Muscle` vocabulary, an equipment value, and a media reference resolving to its bundled thumbnail and remote animation. Exercises without muscle-target metadata MUST NOT exist in the catalog.

#### Scenario: Catalog is available on first launch
- **WHEN** the app launches for the first time
- **THEN** the full dataset-derived catalog is seeded into the local store and every exercise exposes its canonical name, its per-locale name variants, category, primary muscles, secondary muscles, equipment, and media reference

#### Scenario: Seeding is idempotent
- **WHEN** the app launches and the catalog has already been seeded
- **THEN** no duplicate exercises are created

#### Scenario: Dataset taxonomy is mapped to the app vocabulary
- **WHEN** a seeded exercise originating from a dataset record with a target outside the app's muscle vocabulary (e.g. "pectorals") is read from the store
- **THEN** its muscle-target metadata contains only valid `Muscle` raw values (e.g. `chest`)

### Requirement: Catalog covers both measurement types
The catalog SHALL classify every exercise so the UI can determine its input mode: `strength` exercises are measured in repetitions with optional weight; `cardio` exercises are measured in elapsed time.

#### Scenario: Strength exercise classification
- **WHEN** a strength exercise (e.g., bench press) is read from the catalog
- **THEN** its category indicates rep/weight-based measurement

#### Scenario: Cardio exercise classification
- **WHEN** a cardio exercise (e.g., treadmill run) is read from the catalog
- **THEN** its category indicates time-based measurement

### Requirement: Catalog query for selection UI
The app SHALL expose the catalog sorted alphabetically by resolved display name — the name the user actually sees in the current device language — using locale-aware comparison, for display in selection controls.

#### Scenario: Exercise list for selection
- **WHEN** the logging screen requests the exercise list
- **THEN** all catalog exercises are returned sorted alphabetically by their resolved display name under the current locale's comparison rules

#### Scenario: Spanish ordering follows Spanish names
- **WHEN** the exercise list is requested on a Spanish device
- **THEN** the ordering follows the Spanish names, not the canonical English ones

### Requirement: Localized exercise display names
Every exercise in the bundled catalog SHALL carry a canonical English display name plus per-locale name variants for the supported languages (Spanish), imported from the catalog dataset. At display time the name MUST resolve in this order: the stored name verbatim for user-modified exercises; the current device language's name variant when present and non-empty; the canonical English name otherwise. Custom (user-space) exercises carry no name variants and always display their stored name. The exercise's `id`, category, equipment, and muscle-target metadata remain locale-independent serialization values and MUST NOT be affected by name resolution.

#### Scenario: Spanish device resolves the Spanish name
- **WHEN** a catalog exercise carrying a Spanish name variant is displayed on a Spanish device
- **THEN** the Spanish name is shown, while its `id`, category, equipment, and primary/secondary muscle raw values are identical to those resolved on an English device

#### Scenario: English device resolves the canonical name
- **WHEN** the same exercise is displayed on an English device
- **THEN** the canonical English name is shown

#### Scenario: Unsupported language falls back to English
- **WHEN** the same exercise is displayed on a device set to a language with no name variant (e.g. French)
- **THEN** the canonical English name is shown

#### Scenario: User-modified exercise shows its stored name
- **WHEN** an exercise the user has edited and renamed is displayed on a Spanish device
- **THEN** the user's stored name is shown verbatim and the catalog's name variants no longer apply in any language

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
The catalog SHALL be loaded through a data-source abstraction that yields exercise entries (id, canonical name, per-locale name variants, category, primary muscles, secondary muscles, equipment, media reference, description and instruction steps with per-locale variants). The current implementation reads the bundled transformed JSON; the abstraction's entry shape defines the payload contract a future REST catalog endpoint must return, so replacing the source must not require UI or seeding-logic changes. Localization fields MUST decode leniently: an entry that omits them yields empty variant tables rather than a decoding failure.

#### Scenario: Seeding consumes the abstraction
- **WHEN** the catalog seeder runs
- **THEN** it obtains all exercise entries, including equipment, media references, per-locale names, and per-locale content, exclusively through the catalog source abstraction backed by the bundled JSON

#### Scenario: Entry without name variants decodes
- **WHEN** a catalog payload contains an entry with no per-locale name field
- **THEN** the entry decodes successfully with an empty name-variant table

### Requirement: Equipment metadata
Every catalog exercise SHALL carry an equipment value from the dataset's fixed equipment vocabulary, stored as a locale-independent raw string. Equipment display names MUST be localized (English and Spanish) at render time.

#### Scenario: Equipment stored and displayed
- **WHEN** a barbell exercise is displayed on a Spanish device
- **THEN** the stored equipment raw value is unchanged (e.g. `barbell`) and the displayed label is Spanish (e.g. "Barra")

### Requirement: Version-gated seeding
Catalog seeding and alignment SHALL be gated by a bundled catalog version stamp: the bundled catalog JSON is parsed only when the stored version differs from the bundled version, and the stored version is updated after a successful seed. First launch counts as a version change. Any change to the emitted catalog content — including added or corrected per-locale names — MUST be accompanied by a version bump so existing installs realign exactly once.

#### Scenario: Unchanged version skips parsing
- **WHEN** the app launches and the stored catalog version equals the bundled catalog version
- **THEN** the bundled catalog JSON is not parsed and no seeding work occurs

#### Scenario: Version bump triggers reseed
- **WHEN** the app launches with a bundled catalog version newer than the stored one
- **THEN** the catalog is seeded/aligned idempotently and the stored version is updated

#### Scenario: Existing install picks up name variants
- **WHEN** an install seeded before per-locale names existed launches with the newer bundled version
- **THEN** its non-user-modified exercises are aligned to carry the catalog's name variants, and its user-modified exercises are left untouched

