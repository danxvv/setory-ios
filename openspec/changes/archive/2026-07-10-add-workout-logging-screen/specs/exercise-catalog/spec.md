## ADDED Requirements

### Requirement: Bundled exercise catalog
The app SHALL ship with a bundled catalog of predefined exercises. Each exercise MUST have a unique identifier, a display name, a category (`strength` or `cardio`), and muscle-target metadata consisting of at least one primary muscle and zero or more secondary muscles. Exercises without muscle-target metadata MUST NOT exist in the catalog.

#### Scenario: Catalog is available on first launch
- **WHEN** the app launches for the first time
- **THEN** the exercise catalog is seeded into the local store and every exercise exposes its name, category, primary muscles, and secondary muscles

#### Scenario: Seeding is idempotent
- **WHEN** the app launches and the catalog has already been seeded
- **THEN** no duplicate exercises are created

### Requirement: Catalog covers both measurement types
The catalog SHALL classify every exercise so the UI can determine its input mode: `strength` exercises are measured in repetitions with optional weight; `cardio` exercises are measured in elapsed time.

#### Scenario: Strength exercise classification
- **WHEN** a strength exercise (e.g., bench press) is read from the catalog
- **THEN** its category indicates rep/weight-based measurement

#### Scenario: Cardio exercise classification
- **WHEN** a cardio exercise (e.g., treadmill run) is read from the catalog
- **THEN** its category indicates time-based measurement

### Requirement: Catalog query for selection UI
The app SHALL expose the catalog sorted alphabetically by name for display in selection controls.

#### Scenario: Exercise list for the dropdown
- **WHEN** the logging screen requests the exercise list
- **THEN** all catalog exercises are returned sorted alphabetically by display name
